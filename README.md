# ExBanking

Users and operations.
Every user in the system is a two-spawned process that keeps connected.

The PendingOperationServer is a process that saves an operation that should be executed in its state. This state is a queue implementation.

The UserServer is a process that saves a user's balance in its state and it has callback functions to update it.

Example: Three users in the ExBanking system

![alt text](ex_banking.png?raw=true "ExBanking")

Libraries

`typed_struct` - for type describing

`decimal` - for describe and calculate 2 decimal  precision numbers

`elixir_uuid` - for testing only. For creating different users.

`mock` - for testing. To mock some implementation

Run project:

- `./ex_banking iex -S mix run`
- `./ex_banking mix test`


- `docker run -it --rm --name ex_banking -v "$PWD":/usr/src/ex_banking -w /usr/src/ex_banking elixir iex -S mix`
- `docker run -it --rm --name ex_banking -v "$PWD":/usr/src/ex_banking -w /usr/src/ex_banking elixir mix test`