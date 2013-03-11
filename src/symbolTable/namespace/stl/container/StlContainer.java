package symbolTable.namespace.stl.container;

import errorHandling.InvalidStlArguments;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import symbolTable.namespace.CpmClass;
import symbolTable.namespace.DefinesNamespace;
import symbolTable.namespace.SynonymType;
import symbolTable.namespace.stl.iterator.CpmIterator;
import symbolTable.types.Method;
import symbolTable.types.Method.Signature;
import symbolTable.types.Type;
import symbolTable.types.UserDefinedType;

/**
 *
 * @author kostas
 */
public abstract class StlContainer extends CpmClass {
    
        
    private String getUnknownTypeName(Type t){
        return ((UserDefinedType) t).getNamedType().getName();
    }
    
    protected Set<Type> unknownTypes;
    
    protected List<Type> templateArguments;
    
    protected void instatiateTemplateArguments(String[] argNames, SynonymType[] newTypes, Map<String, UserDefinedType> instTypes){
        int i = 0;
        for(String arg : argNames){
            ClassContentElement<SynonymType> old_param = this.innerSynonyms.get(arg);
            SynonymType newType = newTypes[i++];
            this.innerSynonyms.put(arg, new ClassContentElement<SynonymType>(old_param, newType));
            instTypes.put(arg, new UserDefinedType(newType, false, false));
        }
    }
    
    protected void instatiateIterators(String[] iterNames, Type t, Map<String, UserDefinedType> instTypes){
        
        for(String s : iterNames){
            ClassContentElement<CpmClass> elem = this.innerTypes.get(s);
            CpmIterator new_it = new CpmIterator((CpmIterator) elem.getElement(), t);
            ClassContentElement<CpmClass> new_elem = new ClassContentElement<CpmClass>(elem, new_it);
            this.innerTypes.put(s, new_elem);

            instTypes.put(s, new UserDefinedType(new_it, false, false));
        }
    }

    protected void replaceUknownTypes(StlContainer nonInst, Map<String, UserDefinedType> newTypes){
        
        if(this.methods != null){
            for(String methodName : this.methods.keySet()){
                Map< Signature, ClassContentElement<Method>> ms = this.methods.get(methodName);
                for(Signature s : ms.keySet()){
                    ClassContentElement<Method> melem = ms.get(s);
                    Method m = melem.getElement();
                    /*
                     * Return type cannot be null, because it's a method declaration not a constructor.
                     */
                    Type t = m.getReturnType();
                    if(nonInst.unknownTypes.contains(t) == true){
                        String uknownTypeName = nonInst.getUnknownTypeName(t);
                        UserDefinedType newType = newTypes.get(uknownTypeName);
                        s.setReturnValue(newType);
                    }


                    if(s.getParameters() != null){
                        ArrayList<Type> newParams = new ArrayList<Type>();

                        for(Type param : s.getParameters()){
                            Type newType = null;
                            if(nonInst.unknownTypes.contains(param) == true){
                                String unknownTypeName = nonInst.getUnknownTypeName(param);
                                newType = newTypes.get(unknownTypeName);
                            }

                            if(newType == null) newType = param;
                            newParams.add(newType);
                        }

                        s.setParameters(newParams);
                    }
                    
                    ms.put(s, melem);
                }
            }
        }
        
        if(this.constructors != null){
            for(Method.Signature sign : this.constructors.keySet()){
                ClassContentElement<Method> m_elem = this.constructors.get(sign);
                Method m = m_elem.getElement();
                /*Type t = sign.getReturnValue();
                
                if(nonInst.unknownTypes.contains(t) == true){
                    String uknownTypeName = nonInst.getUnknownTypeName(t);
                    UserDefinedType newType = newTypes.get(uknownTypeName);
                    sign.setReturnValue(newType);
                }*/
                
                if(sign.getParameters() != null){
                    ArrayList<Type> newParams = new ArrayList<Type>();
                    
                    for(Type param : sign.getParameters()){
                        Type newType = null;
                        
                        if(nonInst.unknownTypes.contains(param) == true){
                            String unknownTypeName = nonInst.getUnknownTypeName(param);
                            newType = newTypes.get(unknownTypeName);
                        }
                        
                        if(newType == null) newType = param;
                        newParams.add(newType);
                    }
                    
                    sign.setParameters(newParams);
                }
            }
        }

    }
    
    public static StlContainer createGenericContainer(String containerName, DefinesNamespace belongsTo){

        switch(containerName){
            case "vector":
                return new CpmVector(belongsTo);
        }
        //else other cases (will be added later)
        
        return null;
    }
    
    public StlContainer(String name, DefinesNamespace belongsTo){
        super("class", name, belongsTo, null, true);
    }
    
    public StlContainer(StlContainer container){
        super(container);
    }
    
    public abstract CpmClass instantiate(List<Type> args) throws InvalidStlArguments;
    
    @Override
    public StringBuilder getStringName(StringBuilder in){
        StringBuilder rv = super.getStringName(in);
        if(this.templateArguments != null){
            rv.append("<");
            int i;
            for(i = 0 ; i < this.templateArguments.size() - 1 ; ++i){
                rv.append(this.templateArguments.get(i));
                rv.append(",");
            }
            rv.append(this.templateArguments.get(i));
            rv.append(">");
        }
        return rv;
    }
    
}
