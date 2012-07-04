package symbolTable.namespace;

import errorHandling.ErrorMessage;
import java.util.HashMap;
import java.util.HashSet;
import symbolTable.DefinesNamespace;
import symbolTable.types.Method;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class Namespace implements DefinesNamespace{
    
    HashMap<String, HashSet<Type>> allSymbols = new HashMap<String, HashSet<Type>>();
    
    HashMap<String, Type> fields = null;
    
    HashMap<String, HashMap<Method.Signature, Method>> methods = null;
    
    HashMap<String, Namespace> innerNamespaces = null;
    
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
        }
    }
}
