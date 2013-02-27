package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.namespace.CpmClass;

/**
 *
 * @author kostas
 */
public class StrUnClassDefToken extends CommonToken {
    
    private CpmClass _class;
    
    
    public StrUnClassDefToken(int tNode, CpmClass _class){
        super(tNode, "STR_UN_CLASS_DEFINITION");
        this._class = _class;
    }
    
    public CpmClass getCpmClass(){
        return this._class;
    }
    
}
