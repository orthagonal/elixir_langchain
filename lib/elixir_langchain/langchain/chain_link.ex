"""
an individual chainLink in a language chain
when called, a chainlink will
 1. fill in and submit an input prompt, then
 2. add the entire response to the responses list
 3. parse the response with the outputParser
 4. store any output
"""
defmodule ChainLink do
  @derive Jason.Encoder
  defstruct [
    name: "Void",
    input: %Chat{},
    outputParser: &ChainLink.no_parse/2, # take list of all outputs and the ChainLink that evaluated them
    rawResponses: [],  # the actual response returned by the model
    output: %{},  # output can be anything, but a map of variables => values is common
    errors: []  # list of errors that occurred during evaluation
  ]

  def call(chainLink, previousValues \\ %{}) do
    {:ok, evaluatedTemplates } = Chat.format(chainLink.input, previousValues)
    # extract just the role and text fields from each prompt
    modelInputs = Enum.map(evaluatedTemplates, fn evaluatedTemplate -> Map.take(evaluatedTemplate, [:role, :text]) end)
    IO.puts "Model inputs are:"
    IO.inspect chainLink.input.llm
    case LLM.chat(chainLink.input.llm, modelInputs) do
      {:ok, response} ->
        parsed_output = chainLink.outputParser.(response, chainLink)
        %{chainLink |
          rawResponses: response,
          output: parsed_output
        }
      {:error, reason} ->
        IO.inspect reason
        chainLink |> Map.put(:errors, [reason])
    end
  end

  defp noParse(outputs, chainLink) do
    %{
      outputs: outputs,
      response: outputs |> List.first |> Map.get(:text),
      processed_by: chainLink.name
    }
  end
end
