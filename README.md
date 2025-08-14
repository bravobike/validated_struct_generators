# ValidatedStructGenerators

![Tests](https://github.com/bravobike/validated_struct_generators/actions/workflows/main.yaml/badge.svg)
[![Hex version badge](https://img.shields.io/hexpm/v/validated_struct_generators.svg)](https://hex.pm/packages/validated_struct_generators)

This module provides stream data generators for validated structs.

For a validated struct a stream data generator can be created using `&ValidatedStruct.Generator.generator_for/2`.

## Installation

The package can be installed by adding `validated_struct_generators` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:validated_struct_generators, "~> 0.0.1"}
  ]
end
```

## Example

```elixir
ValidatedStruct.Generator.generator_for(MyStruct)
```

### Options for `generator_for/2`

We can provide opts, to influence a generators behaviour:

- :use_defaults? (default: false) uses the default values of a validated struct, instead of
  generating values

- type-based opts (available: :binary, :float, :integer, :atom, :list, :nonempty_list) which are passed
  to the StreamData generators. These hold for all occurances of the type in the structs.

  Example: `ValidatedStruct.Generator.generator_for(MyStruct, [list: [length: 1]])`

- field-based opts - we can define the behaviour of concrete field. To do so, we put the field names with
  either `:opts`, `:const` or `:generator` into the `:fields` option as so:

  Example: `ValidatedStruct.Generator.generator_for(MyStruct, [fields: [repairments: [opts: [length: 1]]]])`

  We can either pass opts to the respective generators, or define our own generator:

  Example: `ValidatedStruct.Generator.generator_for(MyStruct, [fields: [repairments: [generator: StreamData.constant([])]]])`

  The `:const` keyword is a convienience option for `[bike_id: StreamData.constant(my_bike_id)]`

  Example: `ValidatedStruct.Generator.generator_for(MyStruct, [fields: [bike_id: [const: my_bike_id]]])`

  Example: `ValidatedStruct.Generator.generator_for(MyStruct, [fields: [repairments: [generator: StreamData.constant([])]]])`

  To recursively control fields in member structs, we can always place another `fields`-opts beside `opts` or `generator`.

