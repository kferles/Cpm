package symbolTable.namespace;

import errorHandling.ErrorMessage;
import java.util.HashMap;
import java.util.HashSet;
import symbolTable.DefinesNamespace;
import symbolTable.types.Method;
import symbolTable.types.Method.Signature;
import symbolTable.types.Type;
import symbolTable.types.UserDefinedType;

/**
 *
 * @author kostas
 */
public class Namespace implements DefinesNamespace{
    
    HashMap<String, HashSet<Type>> allSymbols = new HashMap<String, HashSet<Type>>();
    
    HashMap<String, Type> fields = null;
    
    HashMap<String, HashMap<Method.Signature, Method>> methods = null;
    
    HashMap<String, Namespace> innerNamespaces = null;
    
    HashMap<String, UserDefinedType> innerTypes = null;
    
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
    
    public void insertField(String name, Type t) throws ErrorMessage{
        if(fields == null) fields = new HashMap<String, Type>();
        if(allSymbols.containsKey(name) == true || innerNamespaces.containsKey(name)) throw new ErrorMessage("");
        //if(fields.containsKey(name)) throw new ErrorMessage(""); //probably useless
        fields.put(name, t);
        insertInAllSymbols(name, t);
    }
    
    public void insertMethod(String name, Method m) throws ErrorMessage{
        if(methods == null) methods = new HashMap<String, HashMap<Method.Signature, Method>>();
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
    
    public void insertInnerType(String name, UserDefinedType t) throws ErrorMessage{
        if(innerTypes == null) innerTypes = new HashMap<String, UserDefinedType>();
        if(allSymbols.containsKey(name) == true || innerNamespaces.containsKey(name) == true) throw new ErrorMessage("");
        if(innerTypes.containsKey(name) == true){
            UserDefinedType t1 = innerTypes.get(name);
            if(t1.isDefined() == false){
                innerTypes.put(name, t);
            }
            else if(t.isDefined() == true){
                throw new ErrorMessage("");
            }
            return; //check this here and in UserDefinedType class
        }
        innerTypes.put(name, t);
    }
    
    public void insertInnerNamespace(String name, Namespace namespace) throws ErrorMessage{
        if(innerNamespaces == null) innerNamespaces = new HashMap<String, Namespace>();
        if(!innerNamespaces.containsKey(name)){
            innerNamespaces.put(name, namespace);
        }
        else{
            /*
             * merging the existing namespace with the extension declaration.
             */
            Namespace exists = innerNamespaces.get(name);
            for(String key : namespace.fields.keySet()){
                Type t = namespace.fields.get(key);
                exists.insertField(name, t);
            }
            for(String key : namespace.methods.keySet()){
                HashMap<Method.Signature, Method> ms = namespace.methods.get(key);
                for(Method m : ms.values()){
                    exists.insertMethod(key, m);
                }
            }
            for(String key : namespace.innerNamespaces.keySet()){
                /*
                 * merge again all the inner namespaces.
                 */
                Namespace n = namespace.innerNamespaces.get(key);
                exists.insertInnerNamespace(key, n);
            }
            for(String key : namespace.innerTypes.keySet()){
                UserDefinedType t = namespace.innerTypes.get(key);
                exists.insertInnerType(name, t);
            }
        }
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
