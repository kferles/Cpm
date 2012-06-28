package symbolTable.types;

import java.util.ArrayList;

/**
 *
 * @author kostas
 */
public class Pointer extends Type{
    
    Type pointsTo;
    
    public Pointer(Type pointsTo){
        this.pointsTo = pointsTo;
    }
    
    @Override
    protected StringBuilder getString(StringBuilder aggr){
        if(pointsTo instanceof Method){
            String end = null;
            Method m = (Method) pointsTo;
            StringBuilder methRv = new StringBuilder();
            methRv.append(m.s.returnValue);
            int rParIndex = methRv.indexOf(")");
            if(rParIndex == -1){
                methRv.append(" (*");
            }
            else{
                String start = methRv.substring(0, rParIndex);
                end = methRv.substring(rParIndex, methRv.length());
                methRv = new StringBuilder(start);
                methRv.append(" (*");
            }
            aggr.append(")(");
            ArrayList<Type> parameters = m.s.parameters;
            int size = parameters.size();
            for(int i = 0 ; i < size ; ++i){
                aggr.append(i == 0 ? "" : ",");
                aggr.append(parameters.get(i));
            }
            aggr.append(")");
            if(end != null)
                aggr.append(end);
            return methRv.append(aggr);
        }
        else{
            aggr.append("*");
            return pointsTo.getString(aggr);
        }
    }
    
    @Override
    public boolean equals(Object o){
        if(o == null) return false;
        if(o instanceof Pointer){
            Pointer p = (Pointer) o;
            return this.pointsTo.equals(p.pointsTo);
        }
        return false;
    }

    @Override
    public int hashCode() {
        int hash = 7;
        hash = 83 * hash + (this.pointsTo != null ? this.pointsTo.hashCode() : 0);
        return hash;
    }
    
    
    public static void main(String[] args){
        PrimitiveType i = new PrimitiveType("int");
        
        PrimitiveType d = new PrimitiveType("double");
        
        Pointer p = new Pointer(i);
        
        Pointer p1 = new Pointer(d);
        
        Pointer pp = new Pointer(p);
        
        Pointer pp1 = new Pointer(p1);
        
        ArrayList<Type> l = new ArrayList<Type>();
        l.add(p);
        l.add(p1);
        Method m = new Method(pp1, l, false, false, false);
        Pointer pm = new Pointer(m);
        Pointer ppm = new Pointer(pm);
        Method m1 = new Method(pm, l, false, false, false);
        Pointer pppm = new Pointer(m1);
        Pointer test = new Pointer(pppm);
        System.out.println(i);
        System.out.println(d);
        System.out.println(pp);
        System.out.println(pp1);
        System.out.println(p);
        System.out.println(p1);
        System.out.println(m);
        System.out.println(pm);
        System.out.println(ppm);
        System.out.println(m1);
        System.out.println(pppm);
        System.out.println(test);
        
        Method m3 = new Method(pppm, l, false, false, false);
        Pointer p3 = new Pointer(m3);
        System.out.println("M3 = " + m3);
        System.out.println(p3);
    }

    @Override
    public boolean subType(Type lhs) {
        throw new UnsupportedOperationException("Not supported yet. ");
    }
}
