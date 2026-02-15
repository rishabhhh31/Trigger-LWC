public with sharing class LeadTriggerHandler {
    public static void createFollowUpTask(List<Lead> leads, Map<Id, Lead> oldLeads){
        List<Task> followUpTasks = new List<Task>();
        for(Lead lead : leads){
            Lead oldLead = oldLeads.get(lead.Id);
            if(oldLead.Status != lead.Status && lead.Status == 'Working - Contacted'){
                String leadName = lead.FirstName + ' ' + lead.LastName;
                Task task = new Task();
                task.Subject = 'Follow Up Task for '+leadName;
                task.WhoId = lead.Id;
                task.ActivityDate = Date.today().addDays(10);
                task.Status = 'In Progress';
                task.Priority = 'High';
                task.Description = 'New Lead: ' + leadName + ' is created in the system. Task the necessary steps';
                task.IsReminderSet = true;
                task.ReminderDateTime = System.now().addHours(1);
                followUpTasks.add(task);
            }
        }
        if(!followUpTasks.isEmpty()){
            insert followUpTasks;
        }
    }
}