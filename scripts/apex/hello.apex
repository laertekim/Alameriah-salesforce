List<In_App_Checklist_Settings__c> settingsToInsert = new List<In_App_Checklist_Settings__c>();

// Record 1
In_App_Checklist_Settings__c setting1 = new In_App_Checklist_Settings__c();
setting1.Name = 'a008d00000Br3Ms';
setting1.ProfileKey__c = '9JqRagBVr0SWJjwsZse7Kw==';
setting1.Sales_Cloud_In_App_Page__c = 'https://cloud.mail.salesforce.com/SalesCloudInAppChecklistV2?';
setting1.CurrencyIsoCode = 'SAR';
// Note: SetupOwnerId will default to Organization level if not specified
settingsToInsert.add(setting1);

// Record 2
In_App_Checklist_Settings__c setting2 = new In_App_Checklist_Settings__c();
setting2.Name = 'In App Checklist Settings (Profile)';
setting2.ProfileKey__c = 'lUWCGXqEaAspwokBuUZhkJT+p6piy10bgaAifWmgiGc=';
setting2.Sales_Cloud_In_App_Page__c = 'https://cloud.mail.salesforce.com/SalesCloudInAppChecklistV2?';
setting2.CurrencyIsoCode = 'SAR';
// Note: You may need to set SetupOwnerId to a specific Profile ID in the target org
// setting2.SetupOwnerId = 'YourProfileIdHere';
settingsToInsert.add(setting2);

// Record 3
In_App_Checklist_Settings__c setting3 = new In_App_Checklist_Settings__c();
setting3.Name = 'In App Checklist Settings (Profile)';
setting3.ProfileKey__c = 'QlUKH85uB409hVA5KMsuuLWZijiegP4A6H3k6e2BCU0=';
setting3.Sales_Cloud_In_App_Page__c = 'https://cloud.mail.salesforce.com/SalesCloudInAppChecklistV2?';
setting3.CurrencyIsoCode = 'SAR';
// Note: You may need to set SetupOwnerId to a specific Profile ID in the target org
// setting3.SetupOwnerId = 'YourProfileIdHere';
settingsToInsert.add(setting3);

try {
    insert settingsToInsert;
    System.debug('Successfully inserted ' + settingsToInsert.size() + ' custom setting records');
    for(In_App_Checklist_Settings__c cs : settingsToInsert) {
        System.debug('Inserted: ' + cs.Name + ' (ID: ' + cs.Id + ')');
    }
} catch(Exception e) {
    System.debug('Error inserting custom settings: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}
