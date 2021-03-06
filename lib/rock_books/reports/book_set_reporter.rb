require_relative '../documents/book_set'

require_relative 'balance_sheet'
require_relative 'income_statement'
require_relative 'multidoc_transaction_report'
require_relative 'receipts_report'
require_relative 'report_context'
require_relative 'transaction_report'
require_relative 'tx_by_account'
require_relative 'tx_one_account'

module RockBooks
class BookSetReporter

  extend Forwardable

  attr_reader :book_set, :output_dir, :filter, :context

  def_delegator :book_set, :all_entries
  def_delegator :book_set, :journals
  def_delegator :book_set, :chart_of_accounts
  def_delegator :book_set, :run_options


  def initialize(book_set, output_dir, filter = nil)
    @book_set = book_set
    @output_dir = output_dir
    @filter = filter
    @context = ReportContext.new(book_set.chart_of_accounts, book_set.journals, 80)
  end


  def call
    check_prequisite_executables
    reports = all_reports(filter)
    create_directories
    create_index_html
    write_reports(reports)
  end


  # All methods after this point are private.

  private def all_reports(filter = nil)

    report_hash = journals.each_with_object({}) do |journal, report_hash|
      key = journal.short_name.to_sym
      report_hash[key] = TransactionReport.new(journal, context).call(filter)
    end

    report_hash[:all_txns_by_date] = MultidocTransactionReport.new(context).call(filter)
    report_hash[:all_txns_by_amount] = MultidocTransactionReport.new(context).call(filter, :amount)
    report_hash[:all_txns_by_acct] = TxByAccount.new(context).call
    report_hash[:balance_sheet] = BalanceSheet.new(context).call
    report_hash[:income_statement] = IncomeStatement.new(context).call

    if run_options.do_receipts
      report_hash[:receipts] = ReceiptsReport.new(context, *missing_existing_unused_receipts).call
    end

    chart_of_accounts.accounts.each do |account|
      key = ('acct_' + account.code).to_sym
      report = TxOneAccount.new(context, account.code).call
      report_hash[key] = report
    end

    report_hash
  end


  private def run_command(command)
    puts "\n----\nRunning command: #{command}"
    stdout, stderr, status = Open3.capture3(command)
    puts "Status was #{status}."
    unless stdout.size == 0
      puts "\nStdout was:\n\n#{stdout}"
    end
    unless stderr.size == 0
      puts "\nStderr was:\n\n#{stderr}"
    end
    puts
    stdout
  end


  private def executable_exists?(name)
    `which #{name}`
    $?.success?
  end


  private def check_prequisite_executables
    raise "Report generation is not currently supported in Windows." if OS.windows?
    required_exes = OS.mac? ? %w(textutil cupsfilter) : %w(txt2html cupsfilter)
    missing_exes = required_exes.reject { |exe| executable_exists?(exe) }
    if missing_exes.any?
      raise "Missing required report generation executable(s): #{missing_exes.join(', ')}. Please install them with your system's package manager."
    end
  end


  private def create_directories
    %w(txt pdf html).each do |format|
      dir = File.join(output_dir, format, SINGLE_ACCT_SUBDIR)
      FileUtils.mkdir_p(dir)
    end
  end


  # "./pdf/short_name.pdf" or "./pdf/single_account/short_name.pdf"
  private def build_filespec(directory, short_name, file_format)
    fragments = [directory, file_format, "#{short_name}.#{file_format}"]
    is_acct_report = /^acct_/.match(short_name)
    if is_acct_report
      fragments.insert(2, SINGLE_ACCT_SUBDIR)
    end
    File.join(*fragments)
  end


  private def create_index_html
    filespec = build_filespec(output_dir, 'index', 'html')
    File.write(filespec, index_html_content)
    puts "Created index.html"
  end


  private def write_reports(reports)

    reports.each do |short_name, report_text|
      txt_filespec = build_filespec(output_dir, short_name, 'txt')
      html_filespec = build_filespec(output_dir, short_name, 'html')
      pdf_filespec = build_filespec(output_dir, short_name, 'pdf')

      File.write(txt_filespec, report_text)

      # Linux & Mac OS
      cupsfilter = -> { run_command("cupsfilter #{txt_filespec} > #{pdf_filespec}") }

      # Mac OS
      textutil = ->(font_size) do
        run_command("textutil -convert html -font 'Courier New Bold' -fontsize #{font_size} #{txt_filespec} -output #{html_filespec}")
      end

      # Linux
      txt2html = -> { run_command("txt2html --preformat_trigger_lines 0 #{txt_filespec} > #{html_filespec}") }

      # Use smaller size for the PDF but larger size for the web pages:
      if OS.mac?
        textutil.(11)
        cupsfilter.()
        textutil.(14)
      else
        txt2html.()
        cupsfilter.()
      end

      hyperlinkized_text, replacements_made = HtmlHelper.convert_receipts_to_hyperlinks(File.read(html_filespec))
      if replacements_made
        File.write(html_filespec, hyperlinkized_text)
      end

      puts "Created reports in txt, html, and pdf for #{"%-20s" % short_name} at #{File.dirname(txt_filespec)}.\n\n\n"
    end
  end


  private def receipt_full_filespec(receipt_filespec)
    File.join(run_options.receipt_dir, receipt_filespec)
  end


  private def missing_existing_unused_receipts
    missing = []
    existing = []
    unused = Dir['receipts/**/*'].select { |s| File.file?(s) }.sort # Remove files as they are found
    unused.map! { |s| "./" +  s }  # Prepend './' to match the data

    all_entries.each do |entry|
      entry.receipts.each do |receipt|
        filespec = receipt_full_filespec(receipt)
        unused.delete(filespec)
        file_exists = File.file?(filespec)
        list = (file_exists ? existing : missing)
        list << { receipt: receipt, journal: entry.doc_short_name }
      end
    end
    [missing, existing, unused]
  end


  private def index_html_content
    erb_filespec = File.join(File.dirname(__FILE__), 'index.html.erb')
    erb = ERB.new(File.read(erb_filespec))
    erb.result_with_hash(
        journals: journals,
        chart_of_accounts: chart_of_accounts,
        run_options: run_options)
  end
end
end
