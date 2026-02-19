public class RecordDescriptor {
    public List<FieldDescriptor> fields { get; private set; }
    
    public RecordDescriptor() {
        this.fields = new List<FieldDescriptor>();
    }
    
    public void addField(FieldDescriptor field) {
        this.fields.add(field);
    }
    
    public List<FieldDescriptor> getFields() {
        return this.fields;
    }
}