package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.namespace.MethodDefinition;
import symbolTable.types.Method;

/**
 *
 * @author kostas
 */
public class MethodToken extends CommonToken {
    
    private Method meth;
    
    private MethodDefinition methDef;
    
    private boolean isConstructor;
    
    private boolean isDestructor;
    
    public MethodToken(int tNode, Method m, MethodDefinition methDef, boolean isConstructor, boolean isDestructor){
        super(tNode, "METHOD");
        this.meth = m;
        this.methDef = methDef;
        this.isConstructor = isConstructor;
        this.isDestructor = isDestructor;
    }
    
    public Method getMethod(){
        return this.meth;
    }
    
    public MethodDefinition getMethodDefinition(){
        return this.methDef;
    }
    
    public boolean isCosntructor(){
        return this.isConstructor;
    }
    
    public boolean isDestructor(){
        return this.isDestructor;
    }
    
}
