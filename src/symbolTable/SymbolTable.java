package symbolTable;

import errorHandling.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Stack;
import symbolTable.namespace.*;
import symbolTable.namespace.stl.container.StlContainer;
import symbolTable.types.Method;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class SymbolTable extends Namespace{
    
    private class ScopeStackElem{
        ScopeType t;
        
        DefinesNamespace scope;
        
        CpmClass.AccessSpecifier access;

        public ScopeStackElem() {
            this.t = type;
            this.access = current_access;
            if(type == ScopeType.Class) this.scope = current_class;
            if(type == ScopeType.Namespace) this.scope = current_namespace;
            if(type == ScopeType.Method) this.scope = current_method;
        }
        
    }
    
    
    enum ScopeType{
        Class,
        Namespace,
        Method
    }
    
    ScopeType type = ScopeType.Namespace;
    
    Namespace current_namespace = this;
    
    CpmClass current_class;
    
    MethodDefinition current_method;
    
    Stack<ScopeStackElem> scopes = new Stack<ScopeStackElem>();
    
    HashMap<Type, Type> cachedTypes = new HashMap<Type, Type>();
    
    CpmClass.AccessSpecifier current_access = null;
    
    private Type getTypeFromCache(Type t){
        return cachedTypes.get(t);
    }
    
    private void addTypeToCache(Type t){
        this.cachedTypes.put(t, t);
    }
    
    private Type typeFromCache(Type t){
        Type stored_t = getTypeFromCache(t);
        if(stored_t == null){
            addTypeToCache(t);
            stored_t = t;
        }
        return stored_t;
    }
    
        public static class NestedNameInfo{

            private String name;
            
            private int line,
                pos;
            
            private boolean isTemplate;
            
            public NestedNameInfo(String name, int line, int pos, boolean isTemplate){
                this.name = name;
                this.line = line;
                this.pos = pos;
                this.isTemplate = isTemplate;
            }
            
            public String getName(){
                return this.name;
            }
            
            public int getLine(){
                return this.line;
            }
            
            public int getPos(){
                return this.pos;
            }
            
            public boolean isTemplate(){
                return this.isTemplate;
            }
            
            @Override
            public boolean equals(Object o){
                if(o == null) return false;
                
                if(o instanceof NestedNameInfo){
                    NestedNameInfo ninf = (NestedNameInfo) o;
                    if(this.name.equals(ninf.name) == false) return false;
                    if(this.line != ninf.line) return false;
                    if(this.pos != ninf.pos) return false;
                    if(this.isTemplate != ninf.isTemplate) return false;
                    
                    return true;
                }
                
                return false;
            }

            @Override
            public int hashCode() {
                int hash = 7;
                hash = 97 * hash + (this.name != null ? this.name.hashCode() : 0);
                hash = 97 * hash + this.line;
                hash = 97 * hash + this.pos;
                hash = 97 * hash + (this.isTemplate ? 1 : 0);
                return hash;
            }
            
            @Override
            public String toString(){
                return this.name + ";" + line + ";" + pos + ";" + isTemplate;
            }

        }
    
    public SymbolTable(){
        super("", null);
        super.visibleTypeNames = new HashMap<String, TypeDefinition>();
        super.innerNamespaces = new HashMap<String, NamespaceElement<Namespace>>();
        super.innerNamespaces.put("std", new NamespaceElement<Namespace>(new Namespace("std", this), null, -1, -1));
    }
    
    public static String getFieldsFullName(DefinesNamespace belongsTo, String name){
        String rv = belongsTo.getFullName();
        if(rv.equals("") == false) rv += "::";
        rv += name;
        return rv;
    }
    
    public void setCurrentAccess(CpmClass.AccessSpecifier access){
        this.current_access = access;
    }
    
    public CpmClass.AccessSpecifier getCurrentAccess(){
        return this.current_access;
    }
    
    public void setCurrentScope(CpmClass scope){
        scopes.push(new ScopeStackElem());
        this.type = ScopeType.Class;
        this.current_class = scope;
    }
    
    public void setCurrentScope(Namespace scope){
        scopes.push(new ScopeStackElem());
        this.type = ScopeType.Namespace;
        this.current_namespace = scope;
    }
    
    public void setCurrentScope(MethodDefinition scope){
        scopes.push(new ScopeStackElem());
        this.type = ScopeType.Method;
        this.current_method = scope;
    }
    
    public void endScope(){
        ScopeStackElem prev = scopes.pop();
        this.type = prev.t;
        this.current_access = prev.access;
        switch(this.type){
            case Class:
                this.current_class = (CpmClass) prev.scope;
                this.current_namespace = null;
                this.current_method = null;
                break;
            case Namespace:
                this.current_namespace = (Namespace) prev.scope;
                this.current_class = null;
                this.current_method = null;
                break;
            case Method:
                this.current_method = (MethodDefinition) prev.scope;
                this.current_class = null;
                this.current_namespace = null;
                break;
        }
    }
    
    public Type insertField(String name, Type t, boolean isStatic, String fileName, int line, int pos) throws ConflictingDeclaration,
                                                                                                              ChangingMeaningOf,
                                                                                                              DiffrentSymbol {
        
        t = typeFromCache(t);
        switch(this.type){
            case Class:
                current_class.insertField(name, t, this.current_access, isStatic, line, pos);
                break;
            case Namespace:
                current_namespace.insertField(name, t, fileName, line, pos);
                break;
            case Method:
                current_method.insertLocalDeclaration(name, t, line, pos);
                break;
        
        }
        
        return t;
    }
    
    public void insertMethod(String name, Method m, boolean isStatic, String fileName, int line, int pos, boolean insideMethodDef) throws ConflictingDeclaration, 
                                                                                                                                          ChangingMeaningOf,
                                                                                                                                          CannotBeOverloaded,
                                                                                                                                          DiffrentSymbol,
                                                                                                                                          ConflictingRVforVirtual,
                                                                                                                                          InvalidCovariantForVirtual,
                                                                                                                                          Redefinition,
                                                                                                                                          InvalidMethodLocalDeclaration{

        Method.Signature signature = m.getSignature();
        Type rv = signature.getReturnValue();
        rv = rv != null ? typeFromCache(rv) : null;
        signature.setReturnValue(rv);
        
        ArrayList<Type> params = signature.getParameters();
        
        if(params != null){
            ArrayList<Type> newParams = new ArrayList<Type>();
            for(Type t : params){
                newParams.add(typeFromCache(t));
            }
            signature.setParameters(newParams);
        }
        
        if(!insideMethodDef){
            switch(this.type){
                case Class:
                    this.current_class.insertMethod(name, m, this.current_access, isStatic, line, pos);
                    break;
                case Namespace:
                    this.current_namespace.insertMethod(name, m, fileName, line, pos);
                    break;
                case Method:
                    throw new InvalidMethodLocalDeclaration("method declarations");
            }
        }
        else{
            ScopeStackElem prev = scopes.peek();
            switch(prev.t){
                case Class:
                    ((CpmClass)prev.scope).insertMethod(name, m, prev.access, isStatic, line, pos);
                    break;
                case Namespace:
                    ((Namespace)prev.scope).insertMethod(name, m, fileName, line, pos);
                    break;
                case Method:
                    throw new InvalidMethodLocalDeclaration("method definitions");
            }
        }
    }
    
    public void insertConstructor(Method m, int line, int pos) throws CannotBeOverloaded{
        Method.Signature signature = m.getSignature();
        ArrayList<Type> params = signature.getParameters();
        
        if(params != null){
            ArrayList<Type> newParams = new ArrayList<Type>();
            for(Type t : params){
                newParams.add(typeFromCache(t));
            }
            signature.setParameters(newParams);
        }
        
        switch(this.type){
            case Class:
                this.current_class.insertConstructor(m, this.current_access, line, pos);
                break;
            case Method:
                /*
                 * constructor defined inside class, so previous scope must be a class. 
                 */
                ScopeStackElem prevScope = this.scopes.peek();
                CpmClass _class = (CpmClass) prevScope.scope;
                _class.insertConstructor(m, prevScope.access, line, pos);
                break;
        }
    }

    public CpmClass insertInnerType(String name, CpmClass cpm_class, boolean isStatic) throws SameNameAsParentClass,
                                                                                          ConflictingDeclaration,
                                                                                          Redefinition,
                                                                                          DiffrentSymbol,
                                                                                          InvalidMethodLocalDeclaration{
        
        switch(this.type){
            case Class:
                this.current_class.insertInnerType(name, cpm_class, this.current_access, isStatic);
                break;
            case Namespace:
                this.current_namespace.insertInnerType(name, cpm_class);
                break;
            case Method:
                throw new InvalidMethodLocalDeclaration("type definitions and forward declarations");
        }
        
        return cpm_class;
    }
    
    public void insertInnerSyn(String name, SynonymType syn) throws SameNameAsParentClass,
                                                                    ConflictingDeclaration,
                                                                    Redefinition,
                                                                    DiffrentSymbol,
                                                                    InvalidMethodLocalDeclaration{
        
        syn.setSynonym(this.typeFromCache(syn.getSynonym()));
        switch(this.type){
            case Class:
                current_class.insertInnerSynonymType(name, syn, this.current_access, false);
                break;
            case Namespace:
                current_namespace.insertInnerSynonym(name, syn);
                break;
            case Method:
                throw new InvalidMethodLocalDeclaration("tyoe definitions");

        }
    }
    
    public void insertMethDefinition(MethodDefinition meth) throws InvalidMethodLocalDeclaration{
    
        switch(this.type){
            case Class:
                this.current_class.insertMethodDefinition(meth);
                break;
            case Namespace:
                this.current_namespace.insertMethodDefinition(meth);
                break;
            case Method:
                throw new InvalidMethodLocalDeclaration("method definitions");
        }
    
    }
    
    public Namespace insertNamespace(String name, Namespace inner_namespace) throws DiffrentSymbol {
        //Todo: think if there is any case that a namespace will be inserted inside a Class ????
        //if(this.type == ScopeType.Class) throw new ErrorMessage("Error: this should not be happening");
        return current_namespace.insertInnerNamespace(name, inner_namespace);
    }
    
    public DefinesNamespace getCurrentNamespace(){
        DefinesNamespace rv = null;
        switch(this.type){
            case Class:
                rv = this.current_class;
                break;
            case Namespace:
                rv = this.current_namespace;
                break;
            case Method:
                rv = this.current_method;
                break;
                
        }
        
        return rv;
    }
    
    public boolean isCurrentNamespaceClass(){
        return this.type == ScopeType.Class;
    }
    
    public TypeDefinition instantiateTemplates(ArrayList<NestedNameInfo> chain, boolean explicitGlobalScope, List<List<Type>> templateArgs){
        TypeDefinition rv = null;

        DefinesNamespace curr = this.getCurrentNamespace();

        NestedNameInfo inf;
        String t_name;
        //int line, pos;
        
        try{
            
            if(chain.isEmpty() == true) return null;
            
            if(chain.size() == 1) {
                inf = chain.get(0);
                t_name = inf.getName();
                TypeDefinition t;
                if(explicitGlobalScope == true) {
                    t = super.findTypeDefinition(t_name, curr, false);
                }
                else{
                    t = curr.isValidTypeDefinition(t_name, false);
                }

                if(inf.isTemplate() == true){
                    StlContainer container = (StlContainer) t;
                    rv = container.instantiate(templateArgs.get(0));
                }
                else{
                    rv = t;         //probalbly usless ...
                }
            }
            else {
                DefinesNamespace runner;
                inf = chain.get(0);
                t_name = inf.getName();
                int templateArgIndex = 0;
                
                if(explicitGlobalScope == true) {
                    runner = super.findNamespace(t_name, curr, false);
                }
                else {
                    runner = curr.findNamespace(t_name, curr, false);
                }
                
                if(inf.isTemplate() == true){
                    StlContainer container = (StlContainer) runner;
                    runner = container.instantiate(templateArgs.get(templateArgIndex++));
                }
                
                int i;
                for(i = 1 ; i < chain.size() - 1 ; ++i){
                    inf = chain.get(i);
                    t_name = inf.getName();
                    runner = runner.findInnerNamespace(t_name, curr, false);
                    
                    if(inf.isTemplate() == true){
                        StlContainer container = (StlContainer) runner;
                        runner = container.instantiate(templateArgs.get(templateArgIndex++));
                    }
                }
                
                inf = chain.get(i);
                t_name = inf.getName();
                rv = runner.findTypeDefinition(t_name, curr, false);
                
                if(inf.isTemplate() == true){
                    StlContainer container = (StlContainer) rv;
                    rv = container.instantiate(templateArgs.get(templateArgIndex++));
                }
            }
        }
        catch(ErrorMessage _){
            //There should be thrown no error message in the try segment,
            //because this method is being called when isValidTypeDefinition predicate (antlr) is true
        }
        
        return rv;
 
    }
    
    public TypeDefinition getNamedTypeFromNestedNameId(ArrayList<NestedNameInfo> chain, boolean explicitGlobalScope, boolean allowNull, boolean ignore_access) 
                                                                                                        throws AccessSpecViolation, 
                                                                                                               AmbiguousReference,
                                                                                                               NotDeclared,
                                                                                                               InvalidScopeResolution,
                                                                                                               DoesNotNameType {
        TypeDefinition rv = null;
        DefinesNamespace curr = this.getCurrentNamespace();
        NestedNameInfo tmp;
        int line, pos;
        if(chain.size() == 1){
            String t_name;
            tmp = chain.get(0);
            t_name = tmp.getName();
            line = tmp.getLine();
            pos = tmp.getPos();
            try{
                if(explicitGlobalScope == true){
                    rv = super.findTypeDefinition(t_name, curr, ignore_access);
                }
                else{
                    rv = curr.isValidTypeDefinition(t_name, ignore_access);
                }
            }
            catch(AmbiguousReference ambiguous){
                ambiguous.setLastValid(null);
                ambiguous.referenceTypeError(line, pos);
                ambiguous.finalizeErrorMessage();
                ambiguous.setIsPending();
                throw ambiguous;
            }
//            catch(AccessSpecViolation access_viol){
//                access_viol.setContextError(line, pos);
//                throw access_viol;
//            }

            if(rv == null && allowNull == false) throw new DoesNotNameType(t_name);
            
        }
        else{
            DefinesNamespace runner;
            tmp = chain.get(0);
            String namespaceName = tmp.getName();
            line = tmp.getLine();
            pos = tmp.getPos();
            DefinesNamespace prev = null;
            int i;
            try{
                if(explicitGlobalScope == true){
                    runner = super.findNamespace(namespaceName, curr, ignore_access);
                }
                else{
                    runner = curr.findNamespace(namespaceName, curr, ignore_access);
                }

                if(runner == null) throw new NotDeclared(namespaceName, line, pos);

                for(i = 1 ; i < chain.size() - 1 ; ++i){
                    prev = runner;
                    tmp = chain.get(i);
                    namespaceName = tmp.getName();
                    line = tmp.getLine();
                    pos = tmp.getPos();
                    runner = runner.findInnerNamespace(namespaceName, curr, ignore_access);
                    if(runner == null) throw new NotDeclared(prev + "::" + namespaceName, line, pos);
                }
                tmp = chain.get(i);
                namespaceName = tmp.getName();
                rv = runner.findTypeDefinition(namespaceName, curr, ignore_access);

                if(rv == null) throw new DoesNotNameType(namespaceName);
            }
            catch(AmbiguousReference ambigoous){
                ambigoous.setLastValid(prev);
                ambigoous.referenceTypeError(line, pos);
                /*
                 * TODO: check if this is ok with previous error messages 
                 */
                /*if(i == chain.size() - 1)*/
                ambigoous.setIsPending();
                //if(ambigoous.isPending() == true){
                ambigoous.finalizeErrorMessage();
                //}
                //else{
                //    ambigoous.finalizeErrorMessage(line, pos);
                //}
                throw ambigoous;
            }
            catch(InvalidScopeResolution invalid){
                invalid.setMessage(prev, namespaceName, line, pos);
                throw invalid;
            }
//            catch(AccessSpecViolation access_viol){
//                access_viol.setContextError(line, pos);
//                throw access_viol;
//            }
        }
        
        return rv;
    }
    
}
