package symbolTable.namespace;

import errorHandling.ErrorMessage;
import java.util.HashMap;
import java.util.HashSet;
import symbolTable.types.Method;
import symbolTable.types.Method.Signature;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class Namespace implements DefinesNamespace{
    
    String name;
    
    HashMap<String, HashSet<Type>> allSymbols = new HashMap<String, HashSet<Type>>();
    
    HashMap<String, Type> fields = null;
    
    HashMap<String, HashMap<Method.Signature, Method>> methods = null;
    
    HashMap<String, Namespace> innerNamespaces = null;
    
    HashMap<String, Class> innerTypes = null;
    
    HashSet<String> visibleTypeNames = null;
    
    Namespace belongsTo;
    
    @Override
    public StringBuilder getStringName(StringBuilder in){
        if(belongsTo == null) return in.append(name);
        return belongsTo.getStringName(in).append("::").append(name);
    }

    private void insertInAllSymbols(String name, Type entry){
        HashSet<Type> set;
        if(allSymbols.containsKey(name) == true){
            set = allSymbols.get(name);
        }
        else{
            set = new HashSet<Type>();
            allSymbols.put(name, set);
        }
        set.add(entry);
    }
    
    public Namespace(String name, Namespace belongsTo){
        this.name = name;
        this.belongsTo = belongsTo;
    }
    
    public void setVisibleTypeNames(HashSet<String> set){
        this.visibleTypeNames = new HashSet<String>(set);
    }
    
    public void insertField(String name, Type t) throws ErrorMessage{
        if(fields == null) fields = new HashMap<String, Type>();
        if(fields.containsKey(name)) throw new ErrorMessage("");
        if(allSymbols.containsKey(name) == true || innerNamespaces.containsKey(name)) throw new ErrorMessage("");
        if(this.visibleTypeNames.contains(name) == true) throw new ErrorMessage("");
        fields.put(name, t);
        insertInAllSymbols(name, t);
    }
    
    public void insertMethod(String name, Method m) throws ErrorMessage{
        if(methods == null) methods = new HashMap<String, HashMap<Method.Signature, Method>>();
        if(this.visibleTypeNames.contains(name) == true) throw new ErrorMessage("");
        if(methods.containsKey(name) == true){
            HashMap<Method.Signature, Method> ms = methods.get(name);
            if(ms.containsKey(m.getSignature())) throw new ErrorMessage("");
            ms.put(m.getSignature(), m);
        }
        else{
            if(allSymbols.containsKey(name) == true || innerNamespaces.containsKey(name) == true) throw new ErrorMessage("");
            HashMap<Method.Signature, Method> new_entry = new HashMap<Method.Signature, Method>();
            new_entry.put(m.getSignature(), m);
            methods.put(name, new_entry);
            insertInAllSymbols(name, m);
        }
    }
    
    public void insertInnerType(String name, Class t) throws ErrorMessage{
        if(innerTypes == null) innerTypes = new HashMap<String, Class>();
        if(allSymbols.containsKey(name) == true || innerNamespaces.containsKey(name) == true) throw new ErrorMessage("");
        if(innerTypes.containsKey(name) == true){
            Class t1 = innerTypes.get(name);
            if(t1.isComplete() == false){
                innerTypes.put(name, t);
            }
            else if(t.isComplete() == true){
                throw new ErrorMessage("");
            }
            return; //check this here and in UserDefinedType class
        }
        this.visibleTypeNames.add(name);
        t.setVisibleTypeNames(this.visibleTypeNames);
        innerTypes.put(name, t);
    }
    
    public void insertInnerNamespace(String name, Namespace namespace) throws ErrorMessage{
        if(innerNamespaces == null) innerNamespaces = new HashMap<String, Namespace>();
        if(this.allSymbols.containsKey(name) == true) throw new ErrorMessage("");
        if(this.innerTypes.containsKey(name) == true) throw new ErrorMessage("");
        if(!innerNamespaces.containsKey(name)){
            namespace.setVisibleTypeNames(this.visibleTypeNames);
            innerNamespaces.put(name, namespace);
        }
        else{
            /*
             * merging the existing namespace with the extension declaration.
             */
            Namespace exists = innerNamespaces.get(name);
            if(namespace.fields != null){
                for(String key : namespace.fields.keySet()){
                    Type t = namespace.fields.get(key);
                    exists.insertField(name, t);
                }
            }
            if(namespace.methods != null){
                for(String key : namespace.methods.keySet()){
                    HashMap<Method.Signature, Method> ms = namespace.methods.get(key);
                    for(Method m : ms.values()){
                        exists.insertMethod(key, m);
                    }
                }
            }
            if(namespace.innerNamespaces != null){
                for(String key : namespace.innerNamespaces.keySet()){
                    /*
                    * merge again all the inner namespaces.
                    */
                    Namespace n = namespace.innerNamespaces.get(key);
                    exists.insertInnerNamespace(key, n);
                }
            }
            if(namespace.innerTypes != null){
                for(String key : namespace.innerTypes.keySet()){
                    Class t = namespace.innerTypes.get(key);
                    exists.insertInnerType(name, t);
                }
            }
        }
    }
    
    @Override
    public String toString(){
        return this.getStringName(new StringBuilder()).toString();
    }

    /*
     * DefinesNamespace methods
     */
    
    @Override
    public Type findSymbol(String name) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Type findSymbol(String name, DefinesNamespace fromNamespace) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public DefinesNamespace findNamespace(String name) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Method findMethod(String name, Signature s) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public Type findField(String name) {
        throw new UnsupportedOperationException("Not supported yet.");
    }
}
