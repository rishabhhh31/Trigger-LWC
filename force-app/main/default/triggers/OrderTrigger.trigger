trigger OrderTrigger on Order (after insert) {
    if(Trigger.isAfter && Trigger.isInsert){
        OrderTriggerHandler.newOrderDateAccountUpdate(Trigger.new);
    }
}