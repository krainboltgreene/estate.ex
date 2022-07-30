defmodule Estate do
  @moduledoc """
  A set of macros for giving behavior to a module relating to creating a state machine in ecto.
  """

  @type machines() :: keyword(events())
  @type machine() :: {atom(), events()}
  @type events() :: keyword(transition())
  @type transitions() :: keyword(String.t())
  @type transition() :: {atom(), String.t()}

  @doc """
  Takes a repository and a list of machines for which this module has a state machine for

      defmodule Core.Users.Account do
        using Ecto.Schema

        ...

        state_machines(
          Core.Repo,
          onboarding_state: [
            complete: [
              converted: "completed"
            ]
          ]
        )
      end

  Here we're defining `onboarding_state`, which is a column on the `Core.Users.Account` schema, it has a single
  event of `complete` which has a transition from `converted` to `completed`.
  """
  @spec state_machines(atom(), machines()) :: any()
  defmacro state_machines(repository, machines) when is_list(machines) do
    Enum.flat_map(machines, &state_machine(&1, repository))
  end

  defp state_machine({column_name, events}, repository)
      when is_list(events) and is_atom(column_name) do
    Enum.flat_map(events, &transitions(&1, column_name, repository))
  end

  defp transitions({event_name, transitions}, column_name, repository)
       when is_atom(event_name) and is_list(transitions) do
    Enum.map(transitions, &transition(&1, event_name, column_name, repository))
  end

  defp transition({from, to}, event_name, column_name, repository) do
    quote do
      @desc "Called before #{unquote(event_name)}, with the changeset"
      @spec unquote(:"before_#{event_name}_from_#{from}")(Ecto.Changeset.t(t())) ::
              Ecto.Changeset.t(t())
      def unquote(:"before_#{event_name}_from_#{from}")(
            %Ecto.Changeset{
              data: %{unquote(column_name) => unquote(Atom.to_string(from))}
            } = changeset
          ) do
        changeset
      end

      @desc "Called after #{unquote(event_name)}, with the changeset"
      @spec unquote(:"after_#{event_name}_from_#{from}")(
              {:ok | :error, Ecto.Changeset.t(t())}
              | Ecto.Changeset.t(t())
            ) :: {:ok | :error, Ecto.Changeset.t(t())} | Ecto.Changeset.t(t())
      def unquote(:"after_#{event_name}_from_#{from}")(
            %Ecto.Changeset{
              changes: %{unquote(column_name) => unquote(to)},
              data: %{unquote(column_name) => unquote(Atom.to_string(from))}
            } = changeset
          ) do
        changeset
      end

      @desc "Called after #{unquote(event_name)}!, with the saved record"
      def unquote(:"after_#{event_name}_from_#{from}")({
            :ok,
            %{
              unquote(column_name) => unquote(to)
            } = record
          }) do
        {:ok, record}
      end

      def unquote(:"after_#{event_name}_from_#{from}")({:error, _} = error), do: error

      @desc "An action to change the state, if the transition matches, but doesn't save"
      @spec unquote(event_name)(%__MODULE__{unquote(column_name) => String.t()}) ::
              Ecto.Changeset.t(t())
      def unquote(event_name)(%{unquote(column_name) => unquote(Atom.to_string(from))} = record) do
        record
        |> Ecto.Changeset.change()
        |> unquote(:"before_#{event_name}_from_#{from}")()
        |> Ecto.Changeset.cast(%{unquote(column_name) => unquote(to)}, [
          unquote(column_name)
        ])
        |> Ecto.Changeset.validate_required(unquote(column_name))
        |> unquote(:"after_#{event_name}_from_#{from}")()
      end
      def unquote(event_name)(%{unquote(column_name) => _}) do
        {:error, :transition_not_valid}
      end

      @desc "An action to change the state, if the transition matches, but does save"
      @spec unquote(:"#{event_name}!")(%__MODULE__{
              :id => String.t(),
              unquote(column_name) => String.t()
            }) :: Ecto.Changeset.t(t())
      def unquote(:"#{event_name}!")(
            %{:id => id, unquote(column_name) => unquote(Atom.to_string(from))} = record
          )
          when not is_nil(id) do
        unquote(repository).transaction(fn ->
          record
          |> Ecto.Changeset.change()
          |> unquote(:"before_#{event_name}_from_#{from}")()
          |> Ecto.Changeset.cast(%{unquote(column_name) => unquote(to)}, [
            unquote(column_name)
          ])
          |> Ecto.Changeset.validate_required(unquote(column_name))
          |> unquote(repository).update()
          |> unquote(:"after_#{event_name}_from_#{from}")()
        end)
      end
    end
  end
end
