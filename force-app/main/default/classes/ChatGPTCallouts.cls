public with sharing class ChatGPTCallouts {
    @AuraEnabled
    public static String askChatGpt(String message){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ChatGPTNamed/chat');
        req.setMethod('POST');
        ChatGPTWrapper gpt = new ChatGPTWrapper();
        gpt.model = 'gpt-4o-mini';
        gpt.messages = new List<MessageWrapper>();
        MessageWrapper msg = new MessageWrapper();
        msg.role = 'user';
        msg.content = message;
        gpt.messages.add(msg);        
        req.setBody(json.serializePretty(gpt));
        req.setTimeout(120000);
        HttpResponse response = new Http().send(req);
        if(response.getStatusCode() == 200){
            ChatCompletionWrapper responseWrapper = (ChatCompletionWrapper)JSON.deserialize(response.getBody(), ChatCompletionWrapper.class);
            return responseWrapper.choices[0].message.content;
        }
        return '';
    }

    public class ChatGPTWrapper{
        public String model;
        public List<MessageWrapper> messages;
    }
    
    public class MessageWrapper{
        public String role;
        public String content;
    }

    public class ChatCompletionWrapper {
        public String id;
        public Integer created;
        public String model;
        public List<Choice> choices;
        public Usage usage;
        public String system_fingerprint;

    }
    public class Choice {
        public String finish_reason;
        public Integer index;
        public Message message;

    }

    public class Message {
        public String content;
        public String role;
    }

    public class Usage {
        public Integer prompt_tokens;
        public Integer completion_tokens;
        public Integer total_tokens;
    }

}
//System.debug(ChatGPTCallouts.askChatGpt('How can I learn coding?'));