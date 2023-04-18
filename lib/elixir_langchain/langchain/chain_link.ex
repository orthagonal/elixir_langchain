"""
an individual chainLink in a language chain
when called, a chainlink will
 1. fill in and submit an input prompt, then
 2. add the entire response to the responses list
 3. parse the response with the outputParser
 4. store any output
"""
defmodule LangChain.ChainLink do
  @derive Jason.Encoder
  defstruct [
    name: "Void",
    input: %LangChain.Chat{},
    outputParser: &LangChain.ChainLink.no_parse/2, # takes in the ChainLink and the list of all responses
    # from the model, pass your own outputParser to parse the output of your chat interactions
    rawResponses: [],  # the actual response returned by the model
    output: %{},  # output should be a map of %{ variable: value } produced by outputParser
    errors: []  # list of errors that occurred during evaluation
  ]

  def call(chainLink, previousValues \\ %{}) do
    {:ok, evaluatedTemplates } = LangChain.Chat.format(chainLink.input, previousValues)
    # extract just the role and text fields from each prompt
    modelInputs = Enum.map(evaluatedTemplates, fn evaluatedTemplate -> Map.take(evaluatedTemplate, [:role, :text]) end)
    case LangChain.LLM.chat(chainLink.input.llm, modelInputs) do
      {:ok, response} ->
        chainLink.outputParser.(chainLink, response)
      {:error, reason} ->
        IO.inspect reason
        chainLink |> Map.put(:errors, [reason])
    end
  end

  # you can define your own parser functions, but this is the default
  # the output of the ChainLink will be used as variables in the next link
  # by default the simple text response goes in the :text key
  defp noParse(chainLink, outputs) do
    %{
      chainLink |
      rawResponses: outputs,
      output: %{ text: outputs |> List.first |> Map.get(:text) }
    }
  end
end

defmodule LangChain.Chain do
  @derive Jason.Encoder
  defstruct [
    links: []  # List of ChainLinks, processed in order
  ]

  def call(lang_chain) do
    call(lang_chain, %{})
  end

  defp call(lang_chain, previous_values) do
    Enum.reduce(lang_chain.links, previous_values, fn chain_link, acc ->
      updated_chain_link = LangChain.ChainLink.call(chain_link, acc)
      # Merge the output of the current ChainLink with the accumulated previous values
      Map.merge(acc, updated_chain_link.output)
    end)
  end
end
