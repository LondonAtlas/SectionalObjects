# SectionalObjects
A demo project to display managed objects on a tableview

## Challenge
Display all `Sections` including one's that do not contain any `Items`

## Description
This project includes a core data model that contains two objects. A `Section`, and an `Item`. Each `Section` can have 0 or more `Items`. The goal is to display all of the `Sections` on a TableView regardless of how many `Items` that they contain. Using a `FetchedResultsController` display all existing `Items`, and sort them by their `Section` name then their `Item` name. Currently, only `Sections` with at least one `Item` are being displayed.

Ideally, use a `FetchedResultsController` so that changes in the data base automatically update with animations.
