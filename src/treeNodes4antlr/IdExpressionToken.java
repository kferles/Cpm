package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class IdExpressionToken extends CommonToken {
    
    private Type t;
    
    public IdExpressionToken(int tNode){
        super(tNode, "ID_EXPRESSION");
    }

    public void setType(Type t){
        this.t = t;
    }
    
    public Type getDeclType(){
        return this.t;
    }
}
