trigger ProjectAssignmentCommentTrigger on Project_Assignment__c (after insert, after update) {
    
    List<Project_Assignment__c> recordsToNotify = new List<Project_Assignment__c>();
    
    for(Project_Assignment__c pa : Trigger.new){
        
        if(Trigger.isInsert && pa.Comments__c != null){
            recordsToNotify.add(pa);
        }
        
        if(Trigger.isUpdate){
            Project_Assignment__c oldRec = Trigger.oldMap.get(pa.Id);
            
            if(pa.Comments__c != oldRec.Comments__c){
                recordsToNotify.add(pa);
            }
        }
    }
    
    if(!recordsToNotify.isEmpty()){
        ProjectAssignmentEmailService.sendCommentNotification(recordsToNotify);
    }
}