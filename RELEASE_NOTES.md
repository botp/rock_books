### v0.6.0

* Linux support added!

### v0.5.0

* Add receipt hyperlinks to HTML output.


## v0.4.0

* Sort unused receipts alphanumerically.
* Add 'x' receipts option for reporting both missing and unused receipts.
* Fix: journals were showing journal account instead of the other account in each transaction.
* Improve Receipts report.


## v0.3.0

* Added ability to report unused receipts.
* Errors now include more context information.
* Improved chart of accounts validation.
* Change license from MIT to Apache 2.


## v0.2.1

* Add help text to readme.


## v0.2.0

* Add instruction manual, modify readme.
* Overhaul generated index.html.
* Add accounting period start and end date to configuration and reports.
* Add validation of transaction dates to ensure within configured date range.
* Make report hash / OpenStruct keys consistently symbols.

## v0.1.6

* Fixed PDF output; PDF files were corrupt because cupsfilter starting sending
output to stderr at some point.


## v0.1.4, v0.1.5

* Intermediate unsatisfactory fixes, these versions were published but yanked. 


## v0.1.3

* Report output now goes to separate txt, html, and pdf subdirectories.
* Add vendor.yml to exclude generated report files from language reporting.
* Use .gitattributes instead of vendor.yml to specify vendored code.
* Add == methods to ChartOfAccounts and Journal classes.
* Rename input files from .rbt to .txt.
* Convert sample input files to DOS line endings.
* Add validation that transaction is balanced.
* Fix so that requesting help shows correct help text, and that passing no args on cmd line triggers help.
* Implement more helpful error messages, with document short name, line number, and line text.
* Add JournalEntryContext and TransactionNotBalancedError classes.
* Add 'from_string' methods to Journal and ChartOfAccounts.


## v0.1.2

* Improve error message when the needed directories do not exist. 


## v0.1.1

* Fix startup error.


## v0.1.0

* First release.

