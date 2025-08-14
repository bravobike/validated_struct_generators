defmodule ValidatedStruct.GeneratorTest do
  use ExUnit.Case
  use ExUnitProperties

  alias ValidatedStruct.Generator
  alias ValidatedStruct.GeneratorTestStructs

  describe "validated structs" do
    property "with string type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.StringStruct)) do
        case s.v do
          v when is_binary(v) -> assert true
          _ -> assert false
        end
      end
    end

    property "with binary type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.BinaryStruct)) do
        case s.v do
          v when is_binary(v) -> assert true
          _ -> assert false
        end
      end
    end

    property "with integer type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.IntegerStruct)) do
        case s.v do
          v when is_integer(v) -> assert true
          _ -> assert false
        end
      end
    end

    property "with struct type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.StructStruct)) do
        case s.v do
          %GeneratorTestStructs.IntegerStruct{} -> assert true
          _ -> assert false
        end
      end
    end

    property "with atom type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.AnyAtomStruct)) do
        case s.v do
          v when is_atom(v) -> assert true
          _ -> assert false
        end
      end
    end

    property "with map type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.MapAnyStruct)) do
        case s.v do
          v when is_map(v) -> assert true
          _ -> assert false
        end
      end
    end

    property "with empty map type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.EmptyMapStruct)) do
        case s.v do
          v when is_map(v) -> assert Enum.empty?(v)
          _ -> assert false
        end
      end
    end

    property "with tuple type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.TupleAnyStruct)) do
        case s.v do
          v when is_tuple(v) -> assert true
          _ -> assert false
        end
      end
    end

    test "with pid type can't be generated" do
      assert_raise(RuntimeError, fn -> Generator.generator_for(GeneratorTestStructs.PidStruct) end)
    end

    test "with port type can't be generated" do
      assert_raise(RuntimeError, fn ->
        Generator.generator_for(GeneratorTestStructs.PortStruct)
      end)
    end

    test "with reference type can't be generated" do
      assert_raise(RuntimeError, fn ->
        Generator.generator_for(GeneratorTestStructs.ReferenceStruct)
      end)
    end

    property "with literal tuple type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.TupleStruct)) do
        case s.v do
          {b, i, j} when is_binary(b) and is_integer(i) and is_integer(j) -> assert true
          _ -> assert false
        end
      end
    end

    property "with union type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.UnionStruct)) do
        case s.v do
          v when is_binary(v) -> assert true
          v when is_integer(v) -> assert true
          _ -> assert false
        end
      end
    end

    property "with pos integer type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.PosIntegerStruct)) do
        case s.v do
          v when is_integer(v) and v > 0 -> assert true
          _ -> assert false
        end
      end
    end

    property "with non neg integer type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.NonNegIntegerStruct)) do
        case s.v do
          v when is_integer(v) and v >= 0 -> assert true
          _ -> assert false
        end
      end
    end

    property "with neg integer type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.NegIntegerStruct)) do
        case s.v do
          v when is_integer(v) and v < 0 -> assert true
          _ -> assert false
        end
      end
    end

    property "with boolean type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.BooleanStruct)) do
        case s.v do
          v when is_boolean(v) -> assert true
          _ -> assert false
        end
      end
    end

    property "with list type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.ListStruct)) do
        case s.v do
          [] -> assert true
          v when is_list(v) -> assert Enum.any?(v, &is_integer/1)
          _ -> assert false
        end
      end
    end

    property "with literal map type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.MapStruct)) do
        case s.v do
          %{} = m -> assert Map.has_key?(m, :foo)
          _ -> assert false
        end
      end
    end

    property "with empty list type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.EmptyListStruct)) do
        case s.v do
          [] -> assert true
          _ -> assert false
        end
      end
    end

    property "with non empty list type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.NonemptyListStruct)) do
        case s.v do
          [] -> assert false
          l when is_list(l) -> assert true
          _ -> assert false
        end
      end
    end

    property "with atom literal type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.AtomStruct)) do
        case s.v do
          :foo -> assert true
          _ -> assert false
        end
      end
    end

    property "with literal boolean type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.LiteralBooleanStruct)) do
        assert s.v
      end
    end

    property "with integer literal type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.LiteralIntegerStruct)) do
        case s.v do
          1 -> assert true
          _ -> assert false
        end
      end
    end

    test "with fun type can't be generated" do
      assert_raise(RuntimeError, fn -> Generator.generator_for(GeneratorTestStructs.FunStruct) end)
    end

    test "generates empty structs" do
      assert %GeneratorTestStructs.EmptyStruct{} ==
               Generator.generator_for(GeneratorTestStructs.EmptyStruct)
               |> ExUnitProperties.pick()
    end

    property "with range literal type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.RangeStruct)) do
        case s.v do
          v when v > 0 and v <= 5 -> assert true
          _ -> assert false
        end
      end
    end

    property "with nil literal type can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.NilStruct)) do
        case s.v do
          nil -> assert true
          _ -> assert false
        end
      end
    end

    property "with a complex struct can be generated" do
      check all(s <- Generator.generator_for(GeneratorTestStructs.ComplexStruct)) do
        assert Enum.all?(s.numbers, fn
                 %GeneratorTestStructs.IntegerStruct{} -> true
                 _ -> false
               end)

        assert %GeneratorTestStructs.BooleanStruct{} = s.a_map.foo
      end
    end

    property "can be generated with custom field opts" do
      check all(
              s <-
                Generator.generator_for(GeneratorTestStructs.ComplexStruct,
                  fields: [numbers: [opts: [length: 1]]]
                )
            ) do
        assert Enum.count(s.numbers) == 1
      end
    end

    property "can be generated with custom geneators" do
      check all(
              s <-
                Generator.generator_for(GeneratorTestStructs.ComplexStruct,
                  fields: [numbers: [fields: [v: [generator: StreamData.constant(8)]]]]
                )
            ) do
        assert Enum.all?(s.numbers, fn %GeneratorTestStructs.IntegerStruct{v: v} -> v == 8 end)
      end
    end
  end
end
