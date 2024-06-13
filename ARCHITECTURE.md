# Architecture

- Create a specification for an abstract SQL schema based on IFC schemas
    - each class has a hidden table
    - each class is a views over joins with parent hierarchy
- implement a duckdb extension that can scan .ifc files as that sql schema
- implement a duckdb extension that can scan .rvt files as that sql schema
- attach/build a tool that can load the geometry from both of those into a viewer
- attach/build a query interface for both of those, possibly connected to the viewer
- attach/build a power BI extension on top of the SQL data
    https://datamonkeysite.com/2022/04/17/using-duckdb-with-powerbi/

## IFSQL
