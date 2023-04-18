# does generic processing that all providers can use
defmodule LLM do
  # these are the defaults values for a LLM model
  defstruct [
    provider: :openai,
    modelName: "text-ada-001",
    maxTokens: 25,
    temperature: 0.5,
    n: 1,
    options: %{} # further provider-specific options can go here
  ]

  # chats is the list of chat msgs in the form:
  #   %{text: "Here's some context: This is a context"},
  #   %{text: "Hello Foo, I'm Bar. Thanks for the This is a context"},
  #   %{text: "I'm an AI. I'm Foo. I'm Bar."},
  #   %{text: "I'm a generic message. I'm Foo. I'm Bar.", role: "test"}
  def chat(model, chats) do
    case model.provider do
      :openai -> Providers.OpenAI.chat(model, chats)
      # :gpt3 -> handle_gpt3_call(model, prompt)
      _ -> "unknown provider #{model.provider}"
    end
  end

  def call(model, prompt) do
    case model.provider do
      :openai -> Providers.OpenAI.call(model, prompt)
      # :gpt3 -> handle_gpt3_call(model, prompt)
      _ -> "unknown provider #{model.provider}"
    end
  end

end
