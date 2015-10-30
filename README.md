## A Currency Simulator Application

### by Martin O'Connor

---

An App for backtesting, storing and comparing FX trading ideas, with a feature rich GUI.

Developed in Objective-C and using Coreplot and FMDB Frameworks, and an SQLite Database.

The database holds bid and ask prices (maximum granularity is 1 second) for currency pairs and the correspoding interest rates for positions.

Trading rules are added in Objective-C, but the code is meant to be modular to enable the easy addition of new types of trading signals and positioning rules.