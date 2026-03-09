public with sharing class ProjectAssignmentEmailService {
    
    public static void sendCommentNotification(List<Project_Assignment__c> records){
        
        // Query required related fields
        List<Project_Assignment__c> fullRecords = [
            SELECT Id,
                   Name,
                   Project__r.Name,
                   Executive_Report__c,
                   Executive_Report__r.Name,
                   Priority_Notes__c,
                   Item__c,
                   Assignment_Description__c,
                   Next_Action_Decision_Required__c,
                   Action_By2__c,
                   Comments__c,
                   LastModifiedBy.Name
            FROM Project_Assignment__c
            WHERE Id IN :records
        ];
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        String recipient = System.Label.Project_Assignment_Email_Recipient;
        
        for(Project_Assignment__c pa : fullRecords){
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            mail.setToAddresses(new List<String>{recipient});
            mail.setSubject('Project Assignment Comment Update - ' + pa.Project__r.Name);
            
            String executiveReportLink = '';
            
            if(pa.Executive_Report__c != null){
                String baseUrl   = URL.getOrgDomainUrl().toExternalForm(); 
                executiveReportLink = '<a href="' + baseUrl + '/' + pa.Executive_Report__c + '" target="_blank">'
                                      + pa.Executive_Report__r.Name + '</a>';
            }
            
            String htmlBody = '';
            
            htmlBody += '<html><body style="font-family: Arial, sans-serif;">';
            htmlBody += '<h2 style="color:#2E86C1;">You have a new Project Assignment Comment Update</h2>';
            htmlBody += '<hr/>';
            
            htmlBody += '<p><b>Executive Report:</b> ' + executiveReportLink + '</p>';
            //project assignment link
            String projectAssignmentLink = '<a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + pa.Id + '" target="_blank">' + pa.Name + '</a>';
            htmlBody += '<p><b>Project Assignment:</b> ' + projectAssignmentLink + '</p>';
            htmlBody += '<p><b>Project Name:</b> ' + pa.Project__r.Name + '</p>';
            htmlBody += '<p><b>Status:</b> ' + pa.Priority_Notes__c + '</p>';
            htmlBody += '<p><b>Item Number:</b> ' + pa.Item__c + '</p>';
            htmlBody += '<p><b>Assignment Description:</b> ' + pa.Assignment_Description__c + '</p>';
            
            htmlBody += '<p><b>Next Action / Status:</b><br/>' 
                        + pa.Next_Action_Decision_Required__c + '</p>';
            htmlBody += '<p><b>Action By:</b> ' + (pa.Action_By2__c != null ? pa.Action_By2__c : 'Not Available') + '</p>';
            
            // Highlighted Comment Section
            htmlBody += '<hr style="margin-top:20px; margin-bottom:20px;"/>';
            htmlBody += '<div style="background-color:#FDEDEC; padding:15px; border-left:6px solid #E74C3C;">';
            htmlBody += '<h3 style="color:#C0392B;">New / Updated Comment</h3>';
            htmlBody += '<p>' + pa.Comments__c + '</p>';
            htmlBody += '<p style="font-size:12px; color:gray;">';
            //space
            htmlBody += '<br/>';
            htmlBody += 'Updated By: ' + pa.LastModifiedBy.Name;
            htmlBody += '</p>';
            htmlBody += '</div>';
            
            htmlBody += '<br/><br/>';
            htmlBody += '<p style="font-size:11px;color:gray;">This is an automated notification.</p>';
            htmlBody += '</body></html>';
            
            mail.setHtmlBody(htmlBody);
            
            emails.add(mail);
        }
        
        if(!emails.isEmpty()){
            Messaging.sendEmail(emails);
        }
    }
}