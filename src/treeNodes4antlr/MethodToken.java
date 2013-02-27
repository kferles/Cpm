package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.types.Method;

/**
 *
 * @author kostas
 */
public class MethodToken extends CommonToken {
    
    private Method meth;
    
    public MethodToken(int tNode, Method m){
        super(tNode, "METHOD");
        this.meth = m;
    }
    
    public Method getMethod(){
        return this.meth;
    }
    
}
