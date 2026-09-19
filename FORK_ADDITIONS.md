# Fork Additions — active_record_doctor

> **Upstream:** [gregnavis/active_record_doctor](https://github.com/gregnavis/active_record_doctor)
>
> This fork tracks upstream and rebases regularly. Contributions and issue reports are welcome.

## New detectors (on `validation-check-constraints` branch)

This fork adds 32 database-design detectors focused on schema discipline for very large PostgreSQL databases. These detectors identify patterns that cause operational problems at scale — missing constraints, suboptimal types, and preventable index bloat.

### Validation-to-constraint detectors

Ensure Rails validators are backed by database constraints:

- **MissingEnumCheckConstraint** — detect enum columns not backed by a database CHECK constraint or native enum type
- **MissingInclusionCheckConstraint** — detect inclusion validators not backed by a database CHECK constraint
- **MissingNumericalityCheckConstraint** — detect numericality validators not backed by a database CHECK constraint
- **MissingStiTypeConstraint** — detect STI type columns not backed by a CHECK constraint on valid class names
- **MissingUniqueIndexes** — detect uniqueness validators not backed by a database constraint

### Type discipline detectors

Enforce correct column types for PostgreSQL:

- **FloatColumn** — detect float columns that should use decimal for precision
- **IntegerShouldBeSmallint** — detect integer columns where smallint would suffice based on enum or validator bounds
- **IpAddressAsString** — detect string columns storing IP addresses that should use inet
- **JsonInsteadOfJsonb** — detect columns using json instead of jsonb
- **SerialPrimaryKey** — detect tables using serial primary keys instead of identity columns
- **StringColumnShouldBeEnum** — detect string columns with inclusion validators that should be Postgres enums
- **UuidStoredAsString** — detect UUID values stored in string columns instead of the native uuid type

### Bounded schema detectors

Prevent unbounded growth and enforce limits:

- **ExcessiveTableIndexes** — detect tables with an excessive number of indexes
- **JsonbWithoutGinIndex** — detect JSONB columns without a GIN index
- **JsonbWithoutShapeConstraint** — detect JSONB columns without a CHECK constraint enforcing jsonb_typeof
- **MissingPolymorphicIndex** — detect polymorphic associations without a composite index on type and id columns
- **NullableBoolean** — detect boolean columns that allow NULL (3-state booleans are an anti-pattern)
- **NullableColumnWithDefault** — detect columns with a default value that are also nullable
- **NullableCounterCache** — detect counter cache columns that are nullable
- **UnboundedHashColumn** — detect hash/digest columns without a fixed-length type or tight limit
- **UnboundedStringColumn** — detect string columns without length caps that hold bounded vocabulary data
- **UnboundedVarcharColumn** — detect varchar columns without a length limit and without a length validator

### Consistency and correctness detectors

- **AmountWithoutPositiveCheck** — detect amount/money columns without a CHECK constraint for positive values
- **BooleanWithoutDefault** — detect boolean columns without a database default value
- **DatetimeWithoutTimezone** — detect timestamp columns defined without timezone
- **EmailWithoutCaseInsensitiveIndex** — detect email columns with case-sensitive unique indexes
- **ForeignKeyOnDeleteMismatch** — detect foreign key ON DELETE actions that mismatch AR dependent options
- **InconsistentCrossTableTypes** — detect columns with the same name but different types across tables
- **InconsistentPrimaryKeyStrategy** — detect tables with primary key types that differ from related tables
- **MissingDefaultInPg** — detect Active Record column defaults not mirrored in the database
- **QueryableJsonbColumn** — detect JSONB columns with store_accessor that may be better as discrete columns
- **UrlColumnWithoutValidation** — detect _url and _uri columns without a format or URI validator

## Installation

This fork is not published to Rubygems. Install from GitHub:

```ruby
gem "active_record_doctor", github: "kierr/active_record_doctor", branch: "validation-check-constraints"
```

**Ruby compatibility:** Tested with Ruby 3.2+. PostgreSQL only (detectors use PostgreSQL-specific introspection).

## Upstream contributions

These detectors are candidates for upstream contribution. If you'd like to see them merged into gregnavis/active_record_doctor, please open or comment on an issue in the upstream repo.
