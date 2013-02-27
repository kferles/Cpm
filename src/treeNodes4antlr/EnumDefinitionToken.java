package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.namespace.SynonymType;

/**
 *
 * @author kostas
 */
public class EnumDefinitionToken extends CommonToken {
    
    private SynonymType _enum;
    
    public EnumDefinitionToken(int tNode, SynonymType _enum){
        super(tNode, "ENUM_DEFINITION");
        this._enum = _enum;
    }
    
    public SynonymType getEnum(){
        return this._enum;
    }
    
}
