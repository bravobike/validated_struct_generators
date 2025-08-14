defmodule ValidatedStruct.Generator do
  @moduledoc """
  This module provides generator functionality for validated structs.
  It should be used using the functions `&Common.struct/2` and `&Common.sample/2`.

  For a validated struct a stream data generator can be created using `&generator_for/2`.

  ## Example

      ValidatedStruct.Generator.generator_for(Event.Workshopping.RepairmentSaved)

  ## Opts

  We can provide opts, to influence a generators behaviour:

  - :use_defaults? (default: false) uses the default values of a validated struct, instead of
    generating values

  - type-based opts (available: :binary, :float, :integer, :atom, :list, :nonempty_list) which are passed
    to the StreamData generators. These hold for all occurances of the type in the structs.

    Example: `ValidatedStruct.Generator.generator_for(Event.Workshopping.RepairmentSaved, [list: [length: 1]])`

  - field-based opts - we can define the behaviour of concrete field. To do so, we put the field names with
    either `:opts`, `:const` or `:generator` into the `:fields` option as so:

    Example: `ValidatedStruct.Generator.generator_for(Event.Workshopping.RepairmentSaved, [fields: [repairments: [opts: [length: 1]]]])`

    We can either pass opts to the respective generators, or define our own generator:

    Example: `ValidatedStruct.Generator.generator_for(Event.Workshopping.RepairmentSaved, [fields: [repairments: [generator: StreamData.constant([])]]])`

    The `:const` keyword is a convienience option for `[bike_id: StreamData.constant(my_bike_id)]`

    Example: `ValidatedStruct.Generator.generator_for(Event.Workshopping.RepairmentSaved, [fields: [bike_id: [const: my_bike_id]]])`

    Example: `ValidatedStruct.Generator.generator_for(Event.Workshopping.RepairmentSaved, [fields: [repairments: [generator: StreamData.constant([])]]])`

    To recursively control fields in member structs, we can always place another `fields`-opts beside `opts` or `generator`.
  """

  alias TypeResolver.Types

  def generator_for(module, opts \\ []) do
    names = module.__field_names__()
    types = module.__types__()

    type_names = Enum.zip(names, types)

    generator_for_helper(module, type_names, names, [], opts |> Keyword.put(:module, module))
  end

  defp generator_for_helper(module, name_to_type, names, acc, opts) do
    case name_to_type do
      [] ->
        names
        |> Enum.zip(acc)
        |> module.make!()
        |> StreamData.constant()

      [{name, type} | rest] ->
        generator = find_generator(type, append_path(opts, name))

        StreamData.bind(generator, fn generated_value ->
          generator_for_helper(module, rest, names, acc ++ [generated_value], opts)
        end)
    end
  end

  defp find_generator(type, opts) do
    case generator_from_opts(opts) do
      nil ->
        case type do
          %Types.NamedType{} = t -> custom(t, opts)
          %Types.BinaryT{} -> binary_generator(opts)
          %Types.IntegerT{} -> integer_generator(opts)
          %Types.StructL{module: s} -> generator_for(s, opts)
          %Types.AtomT{} -> atom_generator(opts)
          %Types.AnyT{} -> any_generator(opts)
          %Types.NoneT{} -> raise "Type None not generateable"
          %Types.MapAnyT{} -> any_map_generator(opts)
          %Types.EmptyMapL{} -> empty_map_generator()
          %Types.TupleAnyT{} -> any_tuple_generator(opts)
          %Types.PidT{} -> raise "not implemented"
          %Types.PortT{} -> raise "not implemented"
          %Types.ReferenceT{} -> raise "not implemented"
          %Types.TupleT{inner: inner} -> tuple_generator(inner, opts)
          %Types.UnionT{inner: inner} -> union_generator(inner, opts)
          %Types.FloatT{} -> float_generator(opts)
          %Types.PosIntegerT{} -> pos_integer_generator()
          %Types.NonNegIntegerT{} -> non_neg_integer_generator()
          %Types.NegIntegerT{} -> neg_integer_generator()
          %Types.BooleanT{} -> boolean_generator()
          %Types.ListT{inner: inner} -> list_generator(inner, opts)
          %Types.MapL{inner: inner} -> map_literal_generator(inner, opts)
          %Types.EmptyListL{} -> empty_list_generator()
          %Types.NonemptyListT{inner: inner} -> nonempty_list_generator(inner, opts)
          %Types.AtomL{value: v} -> StreamData.constant(v)
          %Types.BooleanL{value: v} -> StreamData.constant(v)
          %Types.EmptyBitstringL{} -> empty_bitstring_generator()
          %Types.SizedBitstringL{size: s} -> sized_bitstring_generator(length: s)
          %Types.IntegerL{value: v} -> StreamData.constant(v)
          %Types.FunctionL{arity: _a} -> raise "no implemented"
          %Types.RangeL{from: f, to: t} -> range_generator(f..t, opts)
          %Types.NilL{} -> StreamData.constant(nil)
        end

      generator ->
        generator
    end
  end

  defp range_generator(range, opts) do
    integer_opts = Keyword.get(opts, :integer, []) |> Keyword.merge(range: range)
    integer_generator(opts |> Keyword.merge(integer: integer_opts))
  end

  defp binary_generator(opts) do
    opts = prepare_opts(opts, [], :binary, [:length, :min_length, :max_length])
    StreamData.binary(opts)
  end

  defp float_generator(opts) do
    opts = prepare_opts(opts, [], :float, [:min, :max])
    StreamData.float(opts)
  end

  defp integer_generator(opts) do
    prepare_opts(opts, [], :integer, [:range])
    |> case do
      [range: range] -> StreamData.integer(range)
      _ -> StreamData.integer()
    end
  end

  defdelegate non_neg_integer_generator(), to: StreamData, as: :non_negative_integer
  defdelegate pos_integer_generator(), to: StreamData, as: :positive_integer
  defdelegate boolean_generator(), to: StreamData, as: :boolean

  defp atom_generator(opts) do
    [kind: kind] = prepare_opts(opts, [kind: :alphanumeric], :atom, [:kind])
    StreamData.atom(kind)
  end

  defp any_generator(opts) do
    StreamData.one_of([integer_generator(opts), binary_generator(opts), atom_generator(opts), StreamData.string(:ascii)])
  end

  defp neg_integer_generator(), do: StreamData.integer(-999_999..0)

  defp any_map_generator(opts) do
    StreamData.map_of(any_generator(opts), any_generator(opts))
  end

  defp any_list_generator(opts) do
    list_opts = prepare_opts(opts, [max_length: 5], :list, [:length, :min_length, :max_length])
    StreamData.list_of(any_generator(opts), list_opts)
  end

  defp empty_list_generator() do
    StreamData.constant([])
  end

  defp map_literal_generator(mappings, opts) do
    map_literal_generator_helper(mappings, [], opts)
  end

  defp map_literal_generator_helper([first | rest], generated_values, opts) do
    map_mapping_generator(first, opts)
    |> StreamData.bind(fn result ->
      map_literal_generator_helper(rest, [result | generated_values], opts)
    end)
  end

  defp map_literal_generator_helper([], generated_values, _opts) do
    generated_values
    |> Enum.reject(&is_nil/1)
    |> Map.new()
    |> StreamData.constant()
  end

  defp map_mapping_generator(%Types.MapFieldAssocL{k: key, v: value}, opts) do
    value_generator = StreamData.tuple({find_generator(key, opts), find_generator(value, opts)})
    no_value_generator = StreamData.constant(nil)
    StreamData.frequency([{3, value_generator}, {1, no_value_generator}])
  end

  defp map_mapping_generator(%Types.MapFieldExactL{k: key, v: value}, opts) do
    StreamData.tuple({find_generator(key, opts), find_generator(value, opts)})
  end

  defp empty_bitstring_generator() do
    StreamData.bitstring(length: 0)
  end

  defdelegate sized_bitstring_generator(num), to: StreamData, as: :bitstring

  defp any_tuple_generator(opts) do
    any_list_generator(opts |> Keyword.merge(list: [min_length: 1]))
    |> StreamData.bind(fn res -> StreamData.constant(List.to_tuple(res)) end)
  end

  defp empty_map_generator() do
    StreamData.constant(%{})
  end

  defp nonempty_list_generator(inner, opts) do
    generator_opts = prepare_opts(opts, [max_length: 5], :nonempty_list, [:length, :max_length])

    find_generator(inner, opts)
    |> StreamData.list_of(generator_opts |> Keyword.merge(min_length: 1))
  end

  defp tuple_generator(inner, opts) do
    inner
    |> Enum.map(fn t -> find_generator(t, opts) end)
    |> List.to_tuple()
    |> StreamData.tuple()
  end

  defp union_generator(inner, opts) do
    inner
    |> Enum.map(fn t -> find_generator(t, opts) end)
    |> StreamData.one_of()
  end

  defp list_generator(inner, opts) do
    default_opts = [max_length: 5]
    list_opts = prepare_opts(opts, default_opts, :list, [:length, :min_length, :max_length])

    find_generator(inner, opts) |> StreamData.list_of(list_opts)
  end

  defp custom(%Types.NamedType{inner: inner, module: module, name: name}, opts) do
    lookup = Keyword.get(opts, :lookup, fn _, _ -> nil end)

    lookup.(module, name)
    |> case do
      nil -> find_generator(inner, opts)
      gen -> gen
    end
  end

  defp append_path(opts, name) do
    Keyword.update(opts, :path, [name], fn path -> path ++ [name] end)
  end

  defp prepare_opts(opts, default, type, relevant_fields) do
    path = Keyword.get(opts, :path, [])
    field_opts = get_in(opts, prefix_with_fields(path)) || []

    default
    |> Keyword.merge(Keyword.get(opts, type, []))
    |> Keyword.merge(Keyword.get(field_opts, :opts, []))
    |> Keyword.take(relevant_fields)
  end

  defp generator_from_opts(opts) do
    case maybe_default(opts) do
      nil ->
        field_opts =
          if Keyword.has_key?(opts, :path) do
            path = Keyword.get(opts, :path)
            get_in(opts, prefix_with_fields(path)) || []
          else
            []
          end

        if Keyword.has_key?(field_opts, :const) do
          StreamData.constant(field_opts[:const])
        else
          Keyword.get(field_opts, :generator)
        end

      default ->
        StreamData.constant(default)
    end
  end

  defp maybe_default(opts) do
    case Keyword.get(opts, :path, []) |> List.last() do
      nil ->
        nil

      name ->
        module = Keyword.fetch!(opts, :module)

        if Kernel.function_exported?(module, :__defaults__, 0) do
          Keyword.get(module.__defaults__(), name)
        else
          nil
        end
    end
  end

  defp prefix_with_fields(l) do
    Enum.map(l, fn l -> [:fields, l] end)
    |> List.flatten()
  end
end
