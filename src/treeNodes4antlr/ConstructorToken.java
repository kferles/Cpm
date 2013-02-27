package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.types.Method;

/**
 *
 * @author kostas
 */
public class ConstructorToken extends CommonToken {
    
    private Method constr;
    
    public ConstructorToken(int tNode, Method m){
        super(tNode, "CONSTRUCTOR");
        this.constr = m;
    }
    
    public Method getConstructor(){
        return this.constr;
    }
    
}
