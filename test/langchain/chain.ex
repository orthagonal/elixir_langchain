defmodule LangChain.ChainTest do
  use ExUnit.Case

  # takes list of all outputs and the ChainLink that evaluated them
  def tempParser(outputs, chainlink) do
    %{
      outputs: outputs,
      response: outputs |> List.first |> Map.get(:text),
      processed_by: chainlink.name
    }
  end

  test "Test individual Link" do
    model = %LLM{
      provider: :openai,
      modelName: "text-ada-001",
      maxTokens: 10,
      temperature: 0.5
    }
    chat = Chat.addPromptTemplates(%Chat{}, [
      %{role: "user", prompt: %PromptTemplate{template: "memorize <%= spell %>"}},
      %{role: "user", prompt: %PromptTemplate{template: "cast <%= spell %> on lantern"}},
    ])
    link = %ChainLink{
      name: "enchanter",
      input: chat,
      outputParser: &tempParser/2
    }
    # when we evaluate a chain link, we get a new chain link with the output variables
    newLinkState = ChainLink.call(link, %{spell: "frotz"})
    # make sure it's the right link and the output has the right keys
    assert "enchanter" == newLinkState.output.processed_by
    assert Map.keys(newLinkState.output) == [:outputs, :processed_by, :response]
    IO.inspect newLinkState.output.response # the AI's response won't be the same every time!
  end
end

# chain = %LLMChain{
#   llm: model,
#   prompt: prompt,
#   # input: %{foo: "foo"}
# }
# res = LLMChain.call(chain, %{foo: "my favorite color"})
# IO.inspect res
