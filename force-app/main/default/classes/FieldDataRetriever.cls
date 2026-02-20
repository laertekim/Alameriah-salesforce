public class FieldDataRetriever {
    
    public List<FieldDescriptor> retrieveFields(SObject record, List<String> fieldApiNames, String objectApiName) {
        List<FieldDescriptor> fields = new List<FieldDescriptor>();
        Map<String, Schema.SObjectField> fieldMap = getFieldMap(objectApiName);
        
        for (String fieldApiName : fieldApiNames) {
            if (!fieldMap.containsKey(fieldApiName.toLowerCase())) {
                continue;
            }
            
            Schema.SObjectField field = fieldMap.get(fieldApiName.toLowerCase());
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            
            fields.add(new FieldDescriptor(
                fieldApiName,
                fieldDescribe.getLabel(),
                record.get(fieldApiName),
                fieldDescribe.getType()
            ));
        }
        
        return fields;
    }
    
    public List<RecordDescriptor> retrieveRecords(List<SObject> records, List<String> fieldApiNames, String objectApiName) {
        List<RecordDescriptor> recordDescriptors = new List<RecordDescriptor>();
        
        for (SObject record : records) {
            RecordDescriptor descriptor = new RecordDescriptor();
            List<FieldDescriptor> fields = retrieveFields(record, fieldApiNames, objectApiName);
            
            for (FieldDescriptor field : fields) {
                descriptor.addField(field);
            }
            
            recordDescriptors.add(descriptor);
        }
        
        return recordDescriptors;
    }
    
    private Map<String, Schema.SObjectField> getFieldMap(String objectApiName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        return objectType.getDescribe().fields.getMap();
    }
}