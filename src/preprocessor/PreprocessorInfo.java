/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package preprocessor;

import java.util.Stack;

/**
 *
 * @author kostas
 */
public class PreprocessorInfo {
    
    private class IncludedFile{
        
        String filename = null;
        
        int baseLine;
        
        int preprocFileLine;
        
        int includeLine;
        
        boolean headerPrinted = false;
        
        public IncludedFile(String fileName, int baseLine, int preprocFileLine, int includeLine){
            this.filename = fileName;
            this.baseLine = baseLine;
            this.preprocFileLine = preprocFileLine;
            this.includeLine = includeLine;
        }
        
        public void setBaseLine(int newBase){
            this.baseLine = newBase;
        }
        
        public void setPreprocLine(int preprocLine){
            this.preprocFileLine = preprocLine;
        }
        
        public String getFilenName(){
            return this.filename;
        }
        
        public int getBaseLine(){
            return this.baseLine;
        }
        
        public int getPreprocFileLine(){
            return this.preprocFileLine;
        }
        
        public int getIncludedLine(){
            return this.includeLine;
        }
    }
    
    private Stack<IncludedFile> includedFiles = new Stack<IncludedFile>();
    
    public void enterIncludedFile(String fileName, int baseLine, int preprocFileLine, int includeLine){
        IncludedFile curr = this.includedFiles != null ? (this.includedFiles.isEmpty() ? null : this.includedFiles.peek()) : null;
        if(curr != null && curr.getFilenName().equals(fileName) == true){
            curr.setBaseLine(baseLine);
            curr.setPreprocLine(preprocFileLine);
        }
        else {
            if(curr != null) curr.headerPrinted = false;
            this.includedFiles.push(new IncludedFile(fileName, baseLine, preprocFileLine, includeLine));
        }
    }
    
    public void exitIncludedFile(int newBaseOffset, int includeLine){
        if(this.includedFiles.isEmpty() == false){
            this.includedFiles.pop();
            IncludedFile file = this.includedFiles.peek();
            file.setBaseLine(newBaseOffset - 1);
            file.setPreprocLine(includeLine - 1);
        }
    }
    
    public String getCurrentFileName(){
        if(this.includedFiles.isEmpty() == false) return this.includedFiles.peek().getFilenName();
        else return ""; //this probably is not even possible, relying to cpp's output though :p
    }
    
    public int getOriginalFileLine(int line){
        if(this.includedFiles.isEmpty() == false){
            IncludedFile include = this.includedFiles.peek();
            return include.getBaseLine() + (line - include.getPreprocFileLine()) - 1;
        }
        else{
            return line;
        }
    }
    
    public String getHeaderError(){
        if(this.includedFiles.size() <= 1) return "";
        IncludedFile curr_file = this.includedFiles.peek();
        if(curr_file.headerPrinted == false){
            StringBuilder rv = new StringBuilder("In file included ");
            int size = this.includedFiles.size();
            IncludedFile curr = this.includedFiles.elementAt(size - 1);
            for(int j = size - 2 ; j >= 0 ; --j){
                IncludedFile file = this.includedFiles.elementAt(j);
                if(j != size - 2) rv.append("                 ");
                rv.append("from ");
                rv.append(file.getFilenName());
                rv.append(":");
                rv.append(curr.getIncludedLine());
                if(j == 0){
                    rv.append(":");
                }
                else{
                    rv.append(",");
                }
                curr = file;
                rv.append("\n");
            }
            curr_file.headerPrinted = true;
            return rv.toString();
        }
        else{
            return "";
        }
    }
}
