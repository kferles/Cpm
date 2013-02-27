package treeNodes4antlr;

/**
 *
 * @author kostas
 */
public class EntryLineMarkerToken extends LineMarkerToken {
    
    private String fileName;
    
    private int includeLine;
    
    public EntryLineMarkerToken(int tNode, int baseLine, int preprocLine, boolean isSystemHeader, String fileName, int includeLine){
        super(tNode, baseLine, preprocLine, isSystemHeader);
        this.fileName = fileName;
        this.includeLine = includeLine;
    }
    
    public int getIncludeLine(){
        return this.includeLine;
    }
    
    public String getFileName(){
        return this.fileName;
    }
    
}
