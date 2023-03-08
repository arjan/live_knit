defmodule LiveKnitWeb.Router do
  use LiveKnitWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {LiveKnitWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", LiveKnitWeb do
    pipe_through(:browser)

    live("/", Live.Main)
    live("/analyze", Live.Analyze)
    live("/pat", Live.Pat)
    live("/movie", Live.Movie)
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveKnitWeb do
  #   pipe_through :api
  # end
end
