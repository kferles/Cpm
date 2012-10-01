package symbolTable.namespace;

import errorHandling.AccessSpecViolation;
import errorHandling.AmbiguousReference;
import errorHandling.CannotBeOverloaded;
import errorHandling.ChangingMeaningOf;
import errorHandling.ConflictingDeclaration;
import errorHandling.DiffrentSymbol;
import errorHandling.InvalidScopeResolution;
import errorHandling.Redefinition;
import java.util.HashMap;
import symbolTable.types.Method;
import symbolTable.types.Type;

/*
 * note: line and pos to classes and namespaces (inside the classContent element)
 * are a bit useless for now (but keep them for any case)
 */


/**
 *
 * @author kostas
 */
public class Namespace implements DefinesNamespace{
    
    String name;
    
    protected HashMap<String, NamespaceElement<? extends Type>> allSymbols = new HashMap<String, NamespaceElement<? extends Type>>();
    
    protected HashMap<String, NamespaceElement<Type>> fields = null;
    
    protected HashMap<String, HashMap<Method.Signature, NamespaceElement<Method>>> methods = null;
    
    protected HashMap<String, NamespaceElement<Namespace>> innerNamespaces = null;
    
    protected HashMap<String, NamespaceElement<CpmClass>> innerTypes = null;
    
    protected HashMap<String, NamespaceElement<SynonymType>> innerSynonynms = null;
    
    protected HashMap<String, NamedType> visibleTypeNames = null;
    
    DefinesNamespace belongsTo;
    
    String fileName;
    
    int line, pos;
    
        protected class NamespaceElement <T>{
            
            T element;
            
            String fileName;
            
            int line, pos;
            
            public NamespaceElement(T element, String fileName, int line, int pos){
                this.element = element;
                this.fileName = fileName;
                this.line = line;
                this.pos = pos;
            }
            
        }

    private void insertInAllSymbols(String name, NamespaceElement<? extends Type> entry){
        this.allSymbols.put(name, entry);
    }
    
    private String getFieldsFullName(String field_name){
        String rv = this.belongsTo != null ? this.belongsTo.toString() : "";
        if(rv.equals("") == false) rv += "::";
        rv += field_name;
        return rv;
    }
    
    private void checkForConflictsInDecl(String name, Type t, int line, int pos) throws ConflictingDeclaration{
        if(this.allSymbols.containsKey(name) == true){
            NamespaceElement<? extends Type> old_entry = this.allSymbols.get(name);
            String id = this.getFieldsFullName(name);
            throw new ConflictingDeclaration(id, t, old_entry.element, line, pos, old_entry.fileName, old_entry.line, old_entry.pos);
        }
    }
    
    private void checkForConflictsInDecl(String name, NamedType t, int line, int pos) throws ConflictingDeclaration{
        if(this.allSymbols.containsKey(name) == true){
            NamespaceElement<? extends Type> old_entry = this.allSymbols.get(name);
            String id = this.getFieldsFullName(name);
            throw new ConflictingDeclaration(id, t, old_entry.element, line, pos, old_entry.fileName, old_entry.line, old_entry.pos);
        }
    }
    
    private void checkForConflictsInDecl(String name, Namespace namespace, int line, int pos) throws DiffrentSymbol{
        if(this.allSymbols.containsKey(name) == true){
            NamespaceElement<? extends Type> old_entry = this.allSymbols.get(name);
            String id = this.getFieldsFullName(name);
            throw new DiffrentSymbol(id, namespace, old_entry.element, line, pos, old_entry.fileName, old_entry.line, old_entry.pos);
        }
    }
    
    private void checkForConflictsWithNamespaces(String name, Type t, int line, int pos) throws DiffrentSymbol{
        if(this.innerNamespaces != null && this.innerNamespaces.containsKey(name) == true){
            NamespaceElement<Namespace> namespace = this.innerNamespaces.get(name);
            String id = this.getFieldsFullName(name);
            throw new DiffrentSymbol(id, t, namespace.element, line, pos, namespace.line, namespace.pos);
        }
    }
    
    private void checkForConflictsWithNamespaces(String name, NamedType t, int line, int pos) throws DiffrentSymbol{
        if(this.innerNamespaces != null && this.innerNamespaces.containsKey(name) == true){
            NamespaceElement<Namespace> namespace = this.innerNamespaces.get(name);
            String id = this.getFieldsFullName(name);
            throw new DiffrentSymbol(id, t, namespace.element, line, pos, namespace.line, namespace.pos);
        }
    }
    
    private void checkForChangingMeaningOfType(String name, Type new_entry, int line, int pos) throws ChangingMeaningOf {
        if(this.visibleTypeNames.containsKey(name) == true){
            NamedType t = this.visibleTypeNames.get(name);
            String id = this.getFieldsFullName(name);
            throw new ChangingMeaningOf(id, name, new_entry, t, line, pos);
        }
    }
    
    public Namespace(String name, DefinesNamespace belongsTo){
        this.name = name;
        this.belongsTo = belongsTo;
        if(this.belongsTo != null){
            this.visibleTypeNames = new HashMap<String, NamedType>(this.belongsTo.getVisibleTypeNames());
        }
        else{
            this.visibleTypeNames = new HashMap<String, NamedType>();
        }
    }
    
    public void insertField(String name, Type t, String fileName, int line, int pos) throws ConflictingDeclaration, 
                                                                                            ChangingMeaningOf,
                                                                                            DiffrentSymbol {
        
        if(fields == null) fields = new HashMap<String, NamespaceElement<Type>>();
        this.checkForConflictsInDecl(name, t, line, pos);
        this.checkForChangingMeaningOfType(name, t, line, pos);
        this.checkForConflictsWithNamespaces(name, t, line, pos);
        NamespaceElement<Type> elem = new NamespaceElement<Type>(t, fileName, line, pos);
        fields.put(name, elem);
        insertInAllSymbols(name, elem);
    }
    
    public void insertMethod(String name, Method m, String fileName, int line, int pos) throws CannotBeOverloaded,
                                                                                               ConflictingDeclaration,
                                                                                               ChangingMeaningOf,
                                                                                               DiffrentSymbol,
                                                                                               Redefinition{
        
        if(methods == null) methods = new HashMap<String, HashMap<Method.Signature, NamespaceElement<Method>>>();
        if(methods.containsKey(name) == true){
            HashMap<Method.Signature, NamespaceElement<Method>> ms = methods.get(name);
            if(ms.containsKey(m.getSignature())){
                NamespaceElement<Method> old_m = ms.get(m.getSignature());
                Method old = old_m.element;
                String id = this.getFieldsFullName(name);
                if(m.identicalParameters(old) == true && m.getReturnType().equals(old.getReturnType()) == true){
                    if(m.isDefined() && old.isDefined()){
                        throw new Redefinition(id, m, line, pos, old, old_m.fileName, old_m.line, old_m.pos);
                    }
                }
                else{
                    throw new CannotBeOverloaded(m.toString(id), old_m.element.toString(id), line, pos, old_m.fileName, old_m.line, old_m.pos);
                }
            }
            ms.put(m.getSignature(), new NamespaceElement<Method>(m, fileName, line, pos));
        }
        else{
            this.checkForConflictsInDecl(name, m, line, pos);
            this.checkForChangingMeaningOfType(name, m, line, pos);
            this.checkForConflictsWithNamespaces(name, m, line, pos);
            HashMap<Method.Signature, NamespaceElement<Method>> new_entry = new HashMap<Method.Signature, NamespaceElement<Method>>();
            NamespaceElement<Method> elem = new NamespaceElement<Method>(m, fileName, line, pos);
            new_entry.put(m.getSignature(), elem);
            methods.put(name, new_entry);
            insertInAllSymbols(name, elem);
        }
    }
    
    public void insertInnerType(String name, CpmClass t) throws ConflictingDeclaration,
                                                                DiffrentSymbol,
                                                                Redefinition {
        
        if(innerTypes == null) innerTypes = new HashMap<String, NamespaceElement<CpmClass>>();
        this.checkForConflictsInDecl(name, t, t.line, t.pos);
        this.checkForConflictsWithNamespaces(name, t, t.line, t.pos);
        if(innerTypes.containsKey(name) == true){
            CpmClass t1 = innerTypes.get(name).element;
            if(t1.isComplete() == false){
                innerTypes.put(name, new NamespaceElement<CpmClass>(t, t.fileName, t.line, t.pos));
            }
            else if(t.isComplete() == true){
                throw new Redefinition(t, t1);
            }
            return;
        }
        else if(this.innerSynonynms != null && this.innerSynonynms.containsKey(name) == true){
            NamespaceElement<SynonymType> old_entry = this.innerSynonynms.get(name);
            throw new Redefinition(t, old_entry.element);
        }
        innerTypes.put(name, new NamespaceElement<CpmClass>(t, t.fileName, t.line, t.pos));
        this.visibleTypeNames.put(name, t);
    }
    
    public void insertInnerSynonym(String name, SynonymType syn) throws ConflictingDeclaration,
                                                                        DiffrentSymbol,
                                                                        Redefinition {
        
        if(innerSynonynms == null) innerSynonynms = new HashMap<String, NamespaceElement<SynonymType>>();
        this.checkForConflictsInDecl(name, syn, syn.line, syn.pos);
        this.checkForConflictsWithNamespaces(name, syn, syn.line, syn.pos);
        if(this.innerSynonynms.containsKey(name) == true){
            NamespaceElement<SynonymType> old_entry = this.innerSynonynms.get(name);
            throw new Redefinition(syn, old_entry.element);
        }
        else if(this.innerTypes != null && this.innerTypes.containsKey(name) == true){
            NamespaceElement<CpmClass> old_entry = this.innerTypes.get(name);
            throw new Redefinition(syn, old_entry.element);
        }
        this.innerSynonynms.put(name,  new NamespaceElement<SynonymType>(syn, syn.fileName, syn.line, syn.pos));
        this.visibleTypeNames.put(name, syn);
    }
    
    public Namespace insertInnerNamespace(String name, Namespace namespace) throws DiffrentSymbol{

        if(innerNamespaces == null) innerNamespaces = new HashMap<String, NamespaceElement<Namespace>>();
        this.checkForConflictsInDecl(name, namespace, namespace.line, namespace.pos);
        if(this.innerTypes.containsKey(name) == true) {
            NamespaceElement<CpmClass> old_entry = this.innerTypes.get(name);
            String id = this.getFieldsFullName(name);
            throw new DiffrentSymbol(id, namespace, old_entry.element, namespace.line, namespace.pos, old_entry.line, old_entry.pos);
        }
        else if(this.innerSynonynms.containsKey(name) == true){
            NamespaceElement<SynonymType> old_entry = this.innerSynonynms.get(name);
            String id = this.getFieldsFullName(name);
            throw new DiffrentSymbol(id, namespace, old_entry.element, namespace.line, namespace.pos, old_entry.line, old_entry.pos);
        }
        Namespace rv;
        if(!innerNamespaces.containsKey(name)){
            innerNamespaces.put(name, new NamespaceElement<Namespace>(namespace, namespace.fileName, namespace.line, namespace.pos));
            rv = namespace;
        }
        else{
            /*
             * merging the existing namespace with the extension declaration.
             */
            NamespaceElement<Namespace> elem = this.innerNamespaces.get(name);
            if(elem.fileName == null){
                elem.fileName = namespace.fileName;
                elem.line = namespace.line;
                elem.line = namespace.pos;
            }
            rv = elem.element;
            /*
            if(namespace.fields != null){
                for(String key : namespace.fields.keySet()){
                    NamespaceElement<Type> elem = namespace.fields.get(key);
                    Type t = elem.element;
                    exists.insertField(name, t, namespace.fileName, elem.line, elem.pos);
                }
            }
            if(namespace.methods != null){
                for(String key : namespace.methods.keySet()){
                    HashMap<Method.Signature, NamespaceElement<Method>> ms = namespace.methods.get(key);
                    for(NamespaceElement<Method> m : ms.values()){
                        exists.insertMethod(key, m.element, m.line, m.pos);
                    }
                }
            }
            if(namespace.innerNamespaces != null){
                for(String key : namespace.innerNamespaces.keySet()){
                    ///*
                     //* merge again all the inner namespaces.
                     //
                    NamespaceElement<Namespace> n = namespace.innerNamespaces.get(key);
                    exists.insertInnerNamespace(key, n.element);
                }
            }
            if(namespace.innerTypes != null){
                for(String key : namespace.innerTypes.keySet()){
                    NamespaceElement<CpmClass> t = namespace.innerTypes.get(key);
                    exists.insertInnerType(key, t.element);
                }
            }
            if(namespace.innerSynonynms != null){
                for(String key : namespace.innerSynonynms.keySet()){
                    NamespaceElement<SynonymType> syn = namespace.innerSynonynms.get(key);
                    exists.insertInnerSynonym(key, syn.element);
                }
            }*/
        }
        return rv;
    }
    
    public void setLineAndPos(int line, int pos){
        this.line = line;
        this.pos = pos;
    }
    
    public void setFileName(String fileName){
        this.fileName = fileName;
    }
    
    public String getFileName(){
        return this.fileName;
    }
    
    @Override
    public String toString(){
        return this.getStringName(new StringBuilder()).toString();
    }

    /*
     * DefinesNamespace methods
     */
    
    @Override
    public StringBuilder getStringName(StringBuilder in){
        if(belongsTo == null) return in.append(name);
        StringBuilder parent = this.belongsTo.getStringName(in);
        return parent.append(parent.toString().equals("") ? "" : "::").append(name);
    }
    
    @Override
    public DefinesNamespace getParentNamespace() {
        return this.belongsTo;
    }

    @Override
    public NamedType isValidNamedType(String name, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference {
        NamedType rv = null;
        DefinesNamespace curr_namespace = this;
        while(curr_namespace != null){
            /*
             * from_scope is null because all parents are namespaces.
             */
            rv = curr_namespace.findNamedType(name, null, ignore_access);
            if(rv != null) break;
            curr_namespace = curr_namespace.getParentNamespace();
        }
        return rv;
    }

    @Override
    public NamedType findNamedType(String name, DefinesNamespace _, boolean ignore_access) {
        NamedType rv = null;
        if(this.innerTypes != null && this.innerTypes.containsKey(name) == true){
            rv = this.innerTypes.get(name).element;
        }
        else if(this.innerSynonynms != null && this.innerSynonynms.containsKey(name) == true){
            rv = this.innerSynonynms.get(name).element;
        }
        return rv;
    }
    
    @Override
    public DefinesNamespace findNamespace(String name, DefinesNamespace from_scope, boolean ignore_access) throws AccessSpecViolation, AmbiguousReference, InvalidScopeResolution{
        DefinesNamespace rv;
        rv = this.findInnerNamespace(name, from_scope, ignore_access);
        if(rv == null && this.belongsTo != null){
            rv = this.belongsTo.findNamespace(name, from_scope, ignore_access);
        }
        return rv;
    }
    
    @Override
    public DefinesNamespace findInnerNamespace(String name, DefinesNamespace from_scope, boolean ignore_access) {
        DefinesNamespace rv = null;
        if(this.innerNamespaces != null && this.innerNamespaces.containsKey(name) == true){
            rv = this.innerNamespaces.get(name).element;
        }
        else if(this.innerTypes != null && this.innerTypes.containsKey(name) == true){
            rv = this.innerTypes.get(name).element;
        }
        return rv;
    }
    
    @Override
    public HashMap<String, NamedType> getVisibleTypeNames() {
        return this.visibleTypeNames;
    }
    
    @Override
    public String getFullName(){
        return this.getStringName(new StringBuilder()).toString();
    }
    
    @Override
    public String getName(){
        return this.name;
    }
}
