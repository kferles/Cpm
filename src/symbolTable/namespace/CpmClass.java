package symbolTable.namespace;

import errorHandling.AccessSpecViolation;
import errorHandling.AmbiguousBaseClass;
import errorHandling.AmbiguousReference;
import errorHandling.CannotBeOverloaded;
import errorHandling.ChangingMeaningOf;
import errorHandling.ConflictingDeclaration;
import errorHandling.ConflictingRVforVirtual;
import errorHandling.ErrorMessage;
import errorHandling.InvalidCovariantForVirtual;
import errorHandling.InvalidScopeResolution;
import errorHandling.Redefinition;
import errorHandling.SameNameAsParentClass;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
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
public class CpmClass implements DefinesNamespace, NamedType{
    
    String name;
    
    HashMap<String, ClassContentElement<? extends Type>> allSymbols = new HashMap<String, ClassContentElement<? extends Type>>();
    
    HashSet<CpmClass> superClasses = null;
    
    HashMap<String, ClassContentElement<Type>> fields = null;
    
    HashMap<String, ClassContentElement<CpmClass>> innerTypes = null;
    
    HashMap<String, ClassContentElement<SynonymType>> innerSynonyms = null;
    
    /*
     * Methods are represented as a multi map to support method overloading.
     * That is, every name is maped to another map from a signature to a class Method
     * object. 
     */
    HashMap<String, HashMap<Method.Signature, ClassContentElement<Method>>> methods = null;
    
    HashMap<String, NamedType> visibleTypeNames = null;
    
    DefinesNamespace belongsTo;
    
    String struct_union_or_class;
    
    AccessSpecifier access;
    
    
    /*
     * Line and position within the file.
     * They mostly needed for error messages 
     * that the line is not available through antlr.
     */
    
    int line, pos;
    
    boolean isComplete;

            private class ClassContentElement <T>{
                T element;

                AccessSpecifier access;

                boolean isStatic;
                
                int line, pos;

                public ClassContentElement(T element, AccessSpecifier access, boolean isStatic, int line, int pos){
                    this.element = element;
                    this.access = access;
                    this.isStatic = isStatic;
                    this.line = line;
                    this.pos = pos;
                }

                @Override
                public boolean equals(Object o){
                    return this.element.equals(o);
                }

                @Override
                public int hashCode() {
                    return this.element.hashCode();
                }
            }

    private boolean isOverrider(String name, Method m) throws ConflictingRVforVirtual,
                                                              InvalidCovariantForVirtual{
        if(this.superClasses == null) return false;
        HashSet<ClassContentElement<Method>> methodsInSuper = new HashSet<ClassContentElement<Method>>();
        collectVirtualsInBases(name, m, new HashSet<CpmClass>(), methodsInSuper);
        for(ClassContentElement<Method> method : methodsInSuper){
            try{
                if(m.isOverriderFor(method.element) == false){
                    ConflictingRVforVirtual c_rv = new ConflictingRVforVirtual(name, m, method.element);
                    c_rv.setLineAndPos(method.line, method.pos);
                    throw c_rv;
                }
            }
            catch(AmbiguousBaseClass _){
                InvalidCovariantForVirtual inv = new InvalidCovariantForVirtual(name, m, method.element);
                inv.setLineAndPos(method.line, method.pos);
                throw inv;
            }
        }
        return true;
    }
    
    private void collectVirtualsInBases(String name, Method m, HashSet<CpmClass> visited, HashSet<ClassContentElement<Method>> res){
        if(visited.contains(this) == true) return;
        visited.add(this);
        if(this.methods != null && this.methods.containsKey(name) == true){
            HashMap<Method.Signature, ClassContentElement<Method>> ms = this.methods.get(name);
            ClassContentElement<Method> supermElem = ms.get(m.getSignature());
            if(supermElem != null){
                Method superm = supermElem.element;
                if(superm.isVirtual() == true) res.add(supermElem);
            }
        }
        if(this.superClasses != null){
            for(CpmClass t : this.superClasses){
                t.collectVirtualsInBases(name, m, visited, res);
            }
        }
    }
    
    private String getFieldsFullName(String field_name){
        String rv = this.belongsTo.toString();
        if(rv.equals("") == false) rv += "::";
        rv += field_name;
        return rv;
    }
    
    private void checkForConflictsInDecl(String name, Type t, int line, int pos) throws ConflictingDeclaration{
        if(this.allSymbols.containsKey(name) == true){
            ClassContentElement<? extends Type> old_entry = this.allSymbols.get(name);
            String id = getFieldsFullName(name);
            throw new ConflictingDeclaration(id, t, old_entry.element, line, pos, old_entry.line, old_entry.pos);
        }
    }
    
    private void checkForConflictsInDecl(String name, NamedType t, int line, int pos) throws ConflictingDeclaration{
        if(this.allSymbols.containsKey(name) == true){
            ClassContentElement<? extends Type> old_entry = this.allSymbols.get(name);
            String id = this.getFieldsFullName(name);
            throw new ConflictingDeclaration(id, t, old_entry.element, line, pos, old_entry.line, old_entry.pos);
        }
    }
    
    private void checkForChangingMeaningOfType(String name, Type new_entry, int line, int pos) throws ChangingMeaningOf {
        if(this.visibleTypeNames.containsKey(name) == true){
            NamedType t = this.visibleTypeNames.get(name);
            String id = this.getFieldsFullName(name);
            throw new ChangingMeaningOf(id, name, new_entry, t, line, pos);
        }
    }
    
    private void insertInAllSymbols(String name, ClassContentElement<? extends Type> entry){
        this.allSymbols.put(name, entry);
    }
    
    private int searchSuperType(CpmClass t){
        int count = 0;
        if(this.superClasses != null){
            if(this.superClasses.contains(t) == true) ++count;
            for(CpmClass ut : this.superClasses){
                if(ut.equals(t) == false) count += ut.searchSuperType(t);
            }
        }
        return count;
    }

    private String resolve_access(AccessSpecifier elem_access_spec, DefinesNamespace from_scope){
        String error = null;
        if(from_scope instanceof Namespace){
            if(elem_access_spec == AccessSpecifier.Private){
                error = "is private";
            }
            else if(elem_access_spec == AccessSpecifier.Protected){
                error = "is protected";
            }
        }
        else if(from_scope instanceof CpmClass){
            CpmClass _class = (CpmClass) from_scope;
            if(_class != this){
                if(_class.searchSuperType(this) > 0){
                    if(elem_access_spec == AccessSpecifier.Private){
                        error = "is private";
                    }
                }
                else{
                    if(elem_access_spec == AccessSpecifier.Private){
                        error = "is private";
                    }
                    else if(elem_access_spec == AccessSpecifier.Protected){
                        error = "is protected";
                    }
                }
            }
        }
        return error;
    }
    
    private ArrayList<NamedType> findAllCandidatesTypes(String name,
                                                         DefinesNamespace from_scope, 
                                                         HashSet<CpmClass> visited, 
                                                         ArrayList<NamedType> agr,
                                                         CpmClass first_class,
                                                         ArrayList<String> compl_errors){
        if(visited.contains(this) == true) return agr;
        visited.add(this);
        if(this.innerTypes != null && this.innerTypes.containsKey(name) == true){
            ClassContentElement<CpmClass> _class = this.innerTypes.get(name);
            String access_err = resolve_access(_class.access, from_scope);
            if(access_err != null){
                access_err = "line " + _class.element.line + ":" + _class.element.pos + " error: '" + _class.element.toString() + "' " + access_err;
                compl_errors.add(access_err);
            }
            agr.add(_class.element);
        }
        else if(this.innerSynonyms != null && this.innerSynonyms.containsKey(name) == true){
            ClassContentElement<SynonymType> syn_t = this.innerSynonyms.get(name);
            String access_err = resolve_access(syn_t.access, from_scope);
            if(access_err != null){
                access_err = "line " + syn_t.element.line + ":" + syn_t.element.pos + " error: '" + syn_t.element.toString() + "' " + access_err;
                compl_errors.add(access_err);
            }
            agr.add(syn_t.element);
        }
        
        /*
         * in this case the inner type shadows all possible
         * candidates in super classes.
         */
        if(agr.isEmpty() == false && this == first_class) return agr;
        
        if(this.superClasses != null){
            for(CpmClass _super: this.superClasses){
                if(_super.name.equals(name) == true) agr.add(_super);
                agr = _super.findAllCandidatesTypes(name, from_scope, visited, agr, first_class, compl_errors);
            }
        }
        return agr;
    }
    
    private void addSelfToVisible(){
        this.visibleTypeNames.put(this.name, this);
    }
    
    public void visibleTypesThroughSuperClasses(ArrayList<CpmClass> superTypes){
        HashSet<String> removed = new HashSet<String>();
        if(this.visibleTypeNames == null) this.visibleTypeNames = new HashMap<String, NamedType>();
        if(this.superClasses == null) this.superClasses = new HashSet<CpmClass>();
        for(CpmClass _class : superTypes){
            this.superClasses.add(_class);
            HashMap<String, NamedType> visible_tnames = _class.getVisibleTypeNames();
            for(String t_name : visible_tnames.keySet()){
                if(removed.contains(t_name) == false){
                    if(this.visibleTypeNames.containsKey(t_name) == false){
                        this.visibleTypeNames.put(t_name, visible_tnames.get(t_name));
                    }
                    else{
                        this.visibleTypeNames.remove(t_name);
                        removed.add(t_name);
                    }
                }
            }
        }
        HashMap<String, NamedType> parent_vis = this.belongsTo.getVisibleTypeNames();
        for(String t_name : parent_vis.keySet()){
            if(removed.contains(t_name) == false){
                if(this.visibleTypeNames.containsKey(t_name) == false){
                    this.visibleTypeNames.put(name, parent_vis.get(t_name));
                }
            }
        }
    }
    
    public enum AccessSpecifier{
        Private, 
        Protected,
        Public
    }
    
    /**
     * Constructs a UserDefinedType according to its name.
     * 
     * @param name Type's name.
     * @param isComplete  whether the type is yet implemented or not.
     * @param belongsTo   The namespace that the type belongs to (either a class or a namespace).
     */
    public CpmClass(String struct_union_or_class, String name, DefinesNamespace belongsTo, AccessSpecifier access, boolean isComplete){
        this.name = name;
        this.isComplete = isComplete;
        this.belongsTo = belongsTo;
        this.struct_union_or_class = struct_union_or_class;
        this.visibleTypeNames = new HashMap<String, NamedType>(this.belongsTo.getVisibleTypeNames());
        this.access = access;
        this.addSelfToVisible();
    }
    
    /**
     * Constructs a UserDefinedType that extends some other classes.
     * The ArrayList must contain unique non abstract types so the 
     * constructor will be responsible for no error checking. All these
     * checks must be performed before calling the constructor.
     * @param name          Type's name.
     * @param superTypes    All the super classes.
     * @param belongsTo     The namespace that the type belongs to (either a class or a namespace).
     */
    public CpmClass(String struct_union_or_class, String name, DefinesNamespace belongsTo, ArrayList<CpmClass> superTypes, AccessSpecifier access){
        this.name = name;
        this.struct_union_or_class = struct_union_or_class;
        superClasses = new HashSet<CpmClass>();
        for(CpmClass s : superTypes)
            superClasses.add(s);
        this.isComplete = true;
        this.belongsTo = belongsTo;
        HashSet<String> removed = new HashSet<String>();
        this.visibleTypeNames = new HashMap<String, NamedType>();
        for(CpmClass _class : superTypes){
            HashMap<String, NamedType> visible_tnames = _class.getVisibleTypeNames();
            for(String t_name : visible_tnames.keySet()){
                if(removed.contains(t_name) == false){
                    if(this.visibleTypeNames.containsKey(t_name) == false){
                        this.visibleTypeNames.put(t_name, visible_tnames.get(t_name));
                    }
                    else{
                        this.visibleTypeNames.remove(t_name);
                        removed.add(t_name);
                    }
                }
            }
        }
        HashMap<String, NamedType> parent_vis = this.belongsTo.getVisibleTypeNames();
        for(String t_name : parent_vis.keySet()){
            if(removed.contains(t_name) == false){
                if(this.visibleTypeNames.containsKey(t_name) == false){
                    this.visibleTypeNames.put(name, parent_vis.get(t_name));
                }
            }
        }
        this.access = access;
        this.addSelfToVisible();
    }
    
    /**
     * Insert a field to the current type.
     * 
     * @param name  Field 's name.
     * @param t     A reference to the object that describes field 's type.
     * @return      null if the field is unique inside the Type and an ErrorMessage otherwise.
     */
    public void insertField(String name, Type t, AccessSpecifier access, boolean isStatic, int line, int pos) throws ConflictingDeclaration,
                                                                                                                     ChangingMeaningOf{
        if(fields == null) fields = new HashMap<String, ClassContentElement<Type>>();
        String key = name;
        this.checkForConflictsInDecl(name, t, line, pos);
        this.checkForChangingMeaningOfType(name, t, line, pos);
        ClassContentElement<Type> field = new ClassContentElement<Type>(t, access, isStatic, line, pos);
        fields.put(key, field);
        insertInAllSymbols(key, field);
    }
    
    /**
     * Insert an inner type (i.e nested) to the current type.
     * 
     * @param name Type's name.
     * @param t    A reference to the UserDefinedType object that describes the Type.
     * @return     null if this name is unique inside this scope.
     */
    public void insertInnerType(String name, CpmClass t, AccessSpecifier access, boolean isStatic) throws SameNameAsParentClass,
                                                                                                          ConflictingDeclaration,
                                                                                                          Redefinition{
        if(this.innerTypes == null) this.innerTypes = new HashMap<String, ClassContentElement<CpmClass>>();
        if(name.equals(this.name) == true){
            throw new SameNameAsParentClass(t);
        }
        this.checkForConflictsInDecl(name, t, t.line, t.pos);
        String key = name;
        if(innerTypes.containsKey(key)){
            /*
             * check only if there is another inner type it the same namespace.
             */
            CpmClass t1 = innerTypes.get(key).element;
            if(t1.isComplete == false){
                innerTypes.put(key, new ClassContentElement<CpmClass>(t, access, isStatic, t.line, t.pos));
                return;
            }
            else if(t.isComplete == true){
                throw new Redefinition(t, t1);
            }
            else{
                return;
            }
        }
        else if(this.innerSynonyms != null && this.innerSynonyms.containsKey(key) == true){
            SynonymType syn = this.innerSynonyms.get(key).element;
            throw new Redefinition(t, syn);
        }
        ClassContentElement<CpmClass> elem = new ClassContentElement<CpmClass>(t, access, isStatic, line, pos);
        innerTypes.put(key, elem);
        this.visibleTypeNames.put(key, t);
    }
    
    public void insertInnerSynonymType(String name, SynonymType s, AccessSpecifier access, boolean isStatic) throws SameNameAsParentClass,
                                                                                                                    ConflictingDeclaration,
                                                                                                                    Redefinition{
        
        if(this.innerSynonyms == null) this.innerSynonyms = new HashMap<String, ClassContentElement<SynonymType>>();
        if(name.equals(this.name) == true){
            throw new SameNameAsParentClass(s);
        }
        this.checkForConflictsInDecl(name, s, s.line, s.pos);
        String key = name;
        if(this.innerSynonyms.containsKey(key) == true){
            SynonymType s_old = this.innerSynonyms.get(key).element;
            throw new Redefinition(s_old, s);
        }
        else if(this.innerTypes != null &&this.innerTypes.containsKey(key) == true){
            CpmClass old_entry = this.innerTypes.get(key).element;
            throw new Redefinition(s, old_entry);
        }
        ClassContentElement<SynonymType> elem = new ClassContentElement<SynonymType>(s, access, isStatic, s.line, s.pos);
        innerSynonyms.put(key, elem);
        this.visibleTypeNames.put(key, s);
    }
    
    /**
     * Insert a new method to the current type.
     * 
     * @param name  Method's name.
     * @param m     A reference to the Method object that describes the method
     * @return      null if method can be inserted and an ErrorMessage if method cannot be overloaded.
     */
    public void insertMethod(String name, Method m, AccessSpecifier access, boolean isStatic, int line, int pos) throws ConflictingDeclaration,
                                                                                                                        ChangingMeaningOf,
                                                                                                                        CannotBeOverloaded,
                                                                                                                        ConflictingRVforVirtual,
                                                                                                                        InvalidCovariantForVirtual{

        if(this.methods == null) this.methods = new HashMap<String, HashMap<Method.Signature, ClassContentElement<Method>>>();
        if(this.methods.containsKey(name)){
            HashMap<Method.Signature, ClassContentElement<Method>> m1 = methods.get(name);
            if(m1.containsKey(m.getSignature())){
                ClassContentElement<Method> old_m = m1.get(m.getSignature());
                String id = this.getFieldsFullName(name);
                throw new CannotBeOverloaded(id, m, old_m.element, line, pos, old_m.line, old_m.pos);
            }
            if(isOverrider(name, m) == true) m.setVirtual();
            m1.put(m.getSignature(), new ClassContentElement<Method>(m, access, isStatic, line, pos));
        }
        else{
            checkForConflictsInDecl(name, m, line, pos);
            checkForChangingMeaningOfType(name, m, line, pos);
            HashMap<Method.Signature, ClassContentElement<Method>> m1 = new HashMap<Method.Signature, ClassContentElement<Method>>();
            ClassContentElement<Method> method = new ClassContentElement<Method>(m, access, isStatic, line, pos);
            if(isOverrider(name, m) == true) m.setVirtual();
            m1.put(m.getSignature(), method);
            methods.put(name, m1);
            insertInAllSymbols(name, method);
        }
    }
    
    @Override
    public boolean equals(Object o){
        if(o instanceof CpmClass){
            CpmClass ut = (CpmClass) o;
            if(this.belongsTo == ut.belongsTo && this.name.equals(ut.name)) return true;
            return false;
        }
        else return false;
    }

    @Override
    public int hashCode() {
        int hash = 7;
        hash = 67 * hash + (this.name != null ? this.name.hashCode() : 0);
        hash = 67 * hash + (this.belongsTo != null ? this.belongsTo.hashCode() : 0);
        return hash;
    }
    
    public boolean isCovariantWith(CpmClass c) throws AmbiguousBaseClass {
        if(c == null) return false;
        if(c.equals(this) == true) return true;
        int baseClassCount = searchSuperType(c);
        if(baseClassCount > 1) throw new AmbiguousBaseClass(c, this);
        if(baseClassCount == 1) return true;
        return false;                                       //types are not converiant
    }
    
    public AccessSpecifier getAccess(){
        return this.access;
    }
    
    @Override
    public String toString(){
        return this.struct_union_or_class + " " + this.getStringName(new StringBuilder()).toString();
    }
    
    public boolean isComplete(){
        return this.isComplete;
    }
    
    public void setIsComplete(boolean isComplete){
        this.isComplete = isComplete;
    }

    public void setLineAndPos(int line, int pos){
        this.line = line;
        this.pos = pos;
    }

    public boolean isEnclosedInNamespace(DefinesNamespace namespace){
        boolean rv = false;
        
        DefinesNamespace curr = this.belongsTo;
        while(curr != null){
            if(curr == namespace){
                rv = true;
                break;
            }
            curr = curr.getParentNamespace();
        }
        
        return rv;
    }
    
    public void setTag(String tag){
        this.struct_union_or_class = tag;
    }
    
    //NamedType methods
    
    @Override
    public String getName(){
        return this.getStringName(new StringBuilder()).toString();
    }
    
    @Override
    public int getLine(){
        return this.line;
    }
    
    @Override
    public int getPosition(){
        return this.pos;
    }
    
    @Override
    public String getTag() {
        return this.struct_union_or_class;
    }
    
    @Override
    public CpmClass isClassName() {
        return this;
    }
    
    //DefinesNamespace methods
    
    @Override
    public StringBuilder getStringName(StringBuilder in){
        if(belongsTo == null) return in.append(name);
        StringBuilder parent = this.belongsTo.getStringName(in);
        return parent.append((parent.toString().equals("") ? "" : "::")).append(name);
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
            rv = curr_namespace.findNamedType(name, this, ignore_access);
            if(rv != null) break;
            curr_namespace = curr_namespace.getParentNamespace();
        }
        return rv;
    }

    @Override
    public NamedType findNamedType(String name, DefinesNamespace from_scope, boolean ignore_access) throws AccessSpecViolation, 
                                                                                                           AmbiguousReference{
        NamedType rv = null;
        int res_size;
        ArrayList<String> compl_errors = new ArrayList<String>();
        ArrayList<NamedType> candidatesTypes = findAllCandidatesTypes(name,
                                                                         from_scope,
                                                                         new HashSet<CpmClass>(),
                                                                         new ArrayList<NamedType>(),
                                                                         this,
                                                                         compl_errors);
        if((res_size = candidatesTypes.size()) > 1){
            //here class is ambiguous
            throw new AmbiguousReference(candidatesTypes, name);
        }
        else if(res_size == 1){
            //check for access_spec errors
            if(compl_errors.isEmpty() == false && ignore_access == false){
                /*
                 * access_specs_violation
                 */
                throw new AccessSpecViolation(compl_errors.get(0));
            }
            rv = candidatesTypes.get(0);
        }
        return rv;
    }
    
    @Override
    public DefinesNamespace findNamespace(String name, DefinesNamespace from_scope, boolean ignore_access) throws AccessSpecViolation,
                                                                                                                  AmbiguousReference,
                                                                                                                  InvalidScopeResolution{
        NamedType n_type = this.findNamedType(name, from_scope, ignore_access);
        DefinesNamespace rv = isNameSpace(n_type);

        if(rv == null && this.belongsTo != null){
            rv = this.belongsTo.findNamespace(name, from_scope, ignore_access);
        }
        return rv;
    }
    
    @Override
    public DefinesNamespace findInnerNamespace(String name, DefinesNamespace from_scope, boolean ignore_access) throws AccessSpecViolation,
                                                                                                                       AmbiguousReference,
                                                                                                                       InvalidScopeResolution{
        return isNameSpace(this.findNamedType(name, from_scope, ignore_access));
    }
    
    @Override
    public HashMap<String, NamedType> getVisibleTypeNames() {
        return this.visibleTypeNames;
    }
    
    private DefinesNamespace isNameSpace(NamedType n_type) throws InvalidScopeResolution {
        DefinesNamespace rv = null;
        if(n_type != null){
            if(n_type instanceof DefinesNamespace){
                rv = (DefinesNamespace)n_type;
            }
            else{
                throw new InvalidScopeResolution(); //change this to invalid use of ::
            }
        }
        return rv;
    }

    
}