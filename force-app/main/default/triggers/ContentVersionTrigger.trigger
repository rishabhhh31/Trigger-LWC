trigger ContentVersionTrigger on ContentVersion (after insert) {
    ContentVersionTriggerHandler.createContentDistribution();
}