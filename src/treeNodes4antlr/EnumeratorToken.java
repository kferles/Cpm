package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class EnumeratorToken extends CommonToken{
    
    private Type ernumerator;
    
    public EnumeratorToken(int tNode, Type enumerator){
        super(tNode, "ENUMERATOR");
        this.ernumerator = enumerator;
    }
    
    public Type getEnumerator(){
        return this.ernumerator;
    }
    
}
