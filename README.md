# RetryDemo

Simple example application to demonstrate how you can perform retry operations
simply in elixir using a supervised process.

## Examples

```elixir
alias RetryDemo.UploadServer
```

Simulate successful upload:
```elixir
UploadServer.upload("some_file.doc")
```

Simulate upload failure with retry logic (any file ending with `.fail`):
```elixir
UploadServer.upload("some_file.fail")
```
