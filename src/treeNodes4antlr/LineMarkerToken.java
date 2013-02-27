package treeNodes4antlr;

import org.antlr.runtime.CommonToken;

/**
 *
 * @author kostas
 */
public class LineMarkerToken extends CommonToken{
    
    private int baseLine;
    
    private int preprocLine;
    
    private boolean isSystemHeader;
    
    public LineMarkerToken(int tNode, int baseLine, int preprocLine, boolean isSystemHeader){
        super(tNode, "LINE_MARKER");
        this.baseLine = baseLine;
        this.preprocLine = preprocLine;
        this.isSystemHeader = isSystemHeader;
    }
    
    public int getBaseLine(){
        return this.baseLine;
    }
    
    public int getPreProcLine(){
        return this.preprocLine;
    }
    
    public boolean isSystemHeader(){
        return this.isSystemHeader;
    }
    
}
