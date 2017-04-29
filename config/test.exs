use Mix.Config

config :annon_api, Annon.DB.Configs.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: System.get_env("MIX_TEST_DATABASE") || "annon_api_configs_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :annon_api, Annon.DB.Logger.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: System.get_env("MIX_LOGGER_TEST_DATABASE") || "annon_api_logger_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :ex_statsd,
  sink: [],
  namespace: "test",
  test_mode: true

config :annon_api, :acceptance,
  management: [
    port: {:system, :integer, "MIX_TEST_MANAGEMENT_PORT", 5001},
    host: {:system, "MIX_TEST_HOST", "localhost"}
  ],
  public: [
    port: {:system, :integer, "MIX_TEST_PUBLIC_PORT", 5000},
    host: {:system, "MIX_TEST_HOST", "localhost"}
  ],
  private: [
    port: {:system, :integer, "MIX_TEST_PUBLIC_PORT", 5002},
    host: {:system, "MIX_TEST_HOST", "localhost"}
  ],
  mock: [
    port: {:system, :integer, "TEST_MOCK_PORT", 4040},
    host: {:system, "TEST_MOCK_HOST", "127.0.0.1"}
  ],
  pcm_mock: [
    port: {:system, :integer, "TEST_PCM_MOCK_PORT", 4050},
    host: {:system, "TEST_PCM_MOCK_HOST", "localhost"}
  ]

config :annon_api, :public_http,
  port: {:system, :integer, "GATEWAY_PUBLIC_PORT", 5000}

config :annon_api, :private_http,
  port: {:system, :integer, "GATEWAY_PUBLIC_PORT", 5002}

config :annon_api, :management_http,
  port: {:system, :integer, "GATEWAY_MANAGEMENT_PORT", 5001}

config :logger, level: :debug

config :ex_unit, capture_log: true

config :hackney, use_default_pool: false

config :annon_api,
  cache_storage: {:system, :module, "CACHE_STORAGE", Annon.Cache.PostgresAdapter}

config :annon_api,
  sql_sandbox: {:system, :boolean, "SQL_SANDBOX", true}
