defmodule LangChain.ChainTest do
  use ExUnit.Case

  # takes list of all outputs and the ChainLink that evaluated them
  # returns the new state of the ChainLink
  def tempParser(chainLink, outputs) do
    output = %{
      outputs: outputs,
      text: outputs |> List.first |> Map.get(:text),
      processed_by: chainLink.name
    }

    %LangChain.ChainLink{
      chainLink |
      rawResponses: outputs,
      output: output
    }
  end

  test "Test individual Link" do
    model = %LangChain.LLM{
      provider: :openai,
      modelName: "text-ada-001",
      maxTokens: 10,
      temperature: 0.5
    }
    chat = LangChain.Chat.addPromptTemplates(%LangChain.Chat{}, [
      %{role: "user", prompt: %LangChain.PromptTemplate{template: "memorize <%= spell %>"}},
      %{role: "user", prompt: %LangChain.PromptTemplate{template: "cast <%= spell %> on lantern"}},
    ])
    link = %LangChain.ChainLink{
      name: "enchanter",
      input: chat,
      outputParser: &tempParser/2
    }
    # when we evaluate a chain link, we get a new chain link with the output variables
    newLinkState = LangChain.ChainLink.call(link, %{spell: "frotz"})
    # make sure it's the right link and the output has the right keys
    assert "enchanter" == newLinkState.output.processed_by
    assert Map.keys(newLinkState.output) == [:outputs, :processed_by, :text]
    IO.inspect newLinkState.output.text # the AI's response won't be the same every time!
  end
end
