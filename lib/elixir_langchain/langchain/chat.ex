
# a list of PromptTemplate, constituting the chat dialogue up to that point
defmodule Chat do
  @derive Jason.Encoder
  defstruct [template: "", inputVariables: [], partialVariables: %{}, promptMessages: [], llm: %LLM{}]

  # loops over every prompt and formats it with the values supplied
  def format(chat, values) do
    resultMessages = Enum.map(chat.promptMessages, fn promptMessage ->
      { :ok, text } = PromptTemplate.format(promptMessage.prompt, values)
      Map.put(promptMessage, :text, text)
    end)
    {:ok, resultMessages}
  end

  def toChatMessages do
  end

  def serialize(chat) do
    case Map.has_key?(chat, :output_parser) do
      true -> {:error, "Chat cannot be serialized if output_parser is set"}
      false -> {:ok, %{
        inputVariables: chat.inputVariables,
        promptMessages: Enum.map(chat.promptMessages, &Jason.encode!/1)
      }}
    end
  end

  def addPromptTemplates(chat_prompt_template, prompt_list) do
    updated_prompt_messages = chat_prompt_template.promptMessages ++ prompt_list
    %{chat_prompt_template | promptMessages: updated_prompt_messages}
  end
end
