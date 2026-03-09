public class FieldDataRetriever {
    
    public List<FieldDescriptor> retrieveFields(SObject record, List<String> fieldApiNames, String objectApiName) {
        List<FieldDescriptor> fields = new List<FieldDescriptor>();
        Map<String, Schema.SObjectField> fieldMap = getFieldMap(objectApiName);
        
        for (String fieldApiName : fieldApiNames) {
            // Verifica se é um campo relacional (contém '.__r.')
            if (fieldApiName.contains('__r.')) {
                // Para campos relacionais, precisamos extrair o valor de forma diferente
                String[] relationshipParts = fieldApiName.split('\\.');
                String relationshipName = relationshipParts[0];
                String relatedField = relationshipParts[1];
                
                SObject relatedRecord = record.getSObject(relationshipName);
                if (relatedRecord != null) {
                    Object value = relatedRecord.get(relatedField);
                    
                    // Tenta obter o describe do campo relacional (isso é mais complexo)
                    // Para simplificar, vamos criar um FieldDescriptor com tipo STRING
                    fields.add(new FieldDescriptor(
                        fieldApiName,
                        fieldApiName, // Label será o próprio nome por enquanto
                        value,
                        Schema.DisplayType.STRING
                    ));
                } else {
                    fields.add(new FieldDescriptor(
                        fieldApiName,
                        fieldApiName,
                        null,
                        Schema.DisplayType.STRING
                    ));
                }
            } else {
                // Campo normal
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
        }
        
        return fields;
    }
    
    public List<RecordDescriptor> retrieveRecords(List<SObject> records, List<String> fieldApiNames, String objectApiName) {
        List<RecordDescriptor> recordDescriptors = new List<RecordDescriptor>();
        
        for (SObject record : records) {
            RecordDescriptor descriptor = new RecordDescriptor(record);
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