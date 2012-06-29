/** ANSI C ANTLR v3 grammar

Translated from Jutta Degener's 1995 ANSI C yacc grammar by Terence Parr
July 2006.  The lexical rules were taken from the Java grammar.

Jutta says: "In 1985, Jeff Lee published his Yacc grammar (which
is accompanied by a matching Lex specification) for the April 30, 1985 draft
version of the ANSI C standard.  Tom Stockfisch reposted it to net.sources in
1987; that original, as mentioned in the answer to question 17.25 of the
comp.lang.c FAQ, can be ftp'ed from ftp.uu.net,
   file usenet/net.sources/ansi.c.grammar.Z.
I intend to keep this version as close to the current C Standard grammar as
possible; please let me know if you discover discrepancies. Jutta Degener, 1995"

Generally speaking, you need symbol table info to parse C; typedefs
define types and then IDENTIFIERS are either types or plain IDs.  I'm doing
the min necessary here tracking only type names.  This is a good example
of the global scope (called Symbols).  Every rule that declares its usage
of Symbols pushes a new copy on the stack effectively creating a new
symbol scope.  Also note rule declaration declares a rule scope that
lets any invoked rule see isTypedef boolean.  It's much easier than
passing that info down as parameters.  Very clean.  Rule
direct_declarator can then easily determine whether the IDENTIFIER
should be declared as a type name.

I have only tested this on a single file, though it is 3500 lines.

This grammar requires ANTLR v3.0.1 or higher.

Terence Parr
July 2006
*/ 
grammar Cpm;
options {
    backtrack=true;
    memoize=true;
    k=2;
    output=AST;
}


tokens{
	DECLARATION;
	DECL_SPEC;
	STORAGE_CLASS_SPEC;
	TYPE_QUAL;
	TYPE_SPEC;
	NESTED_ID_GLOBAL;
	NESTED_ID;
	POINTER_DECL;
	POINTER;
	P_DECLARATOR;
	DECLARATOR;
	DECL_SUF;
	ARRAY_CONST_DECL;
	ARRAY_DECL;
	PARAM_LIST;
	QUAL_POINTER;
	PARAM;
	P_ABS_DECLARATOR;
	ABS_DECLARATOR;
}

scope Class{
	boolean inClass;
	String className;
	boolean isVirtual;
	boolean isTypedef;
	boolean isPureVirtual;
	String token3;
	ArrayList<Types> superClasses;
}

@header {
import java.util.Set;
import java.util.HashSet;
import java.util.ArrayList;
import java.util.List;
import types.Types;
}

@members {
	Stack paraphrases = new Stack();
	int access = 4;
	Types global = new Types("", null, access);
	Types current_scope = global;
	HashSet<String> NameSpaces = new HashSet<String>();
	
	public String getErrorMessage(RecognitionException e, String[] tokenNames){
		/*if(paraphrases.size() > 0){
			String rv = "";
			for(Object o : paraphrases)
				rv += (String) o;
			paraphrases.clear();
			return rv;
		}*/
		return super.getErrorMessage(e, tokenNames);
	}

	/*boolean isTypeName(String name) {
		for (int i = Symbols_stack.size()-1; i>=0; i--) {
			Symbols_scope scope = (Symbols_scope)Symbols_stack.get(i);
			if ( scope.types.contains(name) ) {
				return true;
			}
		}
		return false;
	}*/
	
	boolean className(String name){
		Class_scope s = (Class_scope)Class_stack.get(Class_stack.size()-1);
		/*System.out.println("..."+name);
		System.out.println(s);
		System.out.println(s.inClass);
		System.out.println(s.className);*/
		return s.className.equals(name);
	}
	
	Types getTypeName(ArrayList<String> types, boolean from_global){	//System.out.println(types.contains(name) + " " + name);
		Types curr;
		String accessing_scope = current_scope.getName();
		int backtrack = state.backtracking;
		if(from_global){
			curr = global.getNestedType(types.get(0), accessing_scope, backtrack, paraphrases);
			if(curr == null) return null;
		}
		else{
			curr = current_scope.getNestedType(types.get(0), accessing_scope, backtrack, paraphrases);
			if(curr == null) curr = global.getNestedType(types.get(0), accessing_scope, backtrack, paraphrases);
			if(curr == null) return null;
		}
		for(int i = 1 ; i < types.size() ; ++i){
			Types tmp = curr.getNestedType(types.get(i), accessing_scope, backtrack, paraphrases);
			if(tmp == null) return null;
			curr = tmp;
		}
		//Thread.dumpStack();
		//System.out.println(name);
		/*System.out.println("Types");
		for(String t : Alltypes) System.out.println(t);*/
		return curr;
	}
	
	boolean isTypeName(ArrayList<String> types, boolean from_global){
		//if(types.size() == 0) return false;
		return getTypeName(types, from_global) != null;
	}
	
	boolean isNameSpace(String name){
		return NameSpaces.contains(name);
	}
	
	boolean isTemplateType(String name){
		if(name.equals("list")) return true;
		return false;
	}
	
	Tree getChildren(CommonTree t){
		List l = t.getChildren();
		CommonTree rv = new CommonTree();
		if(l != null)
			for(Object o : l) rv.addChild((CommonTree)o);
		return rv;
	}
	
	Tree createTreeFromList(List nodes){
		CommonTree rv = new CommonTree();
		if(nodes != null)
			for(Object o : nodes) rv.addChild((CommonTree)o);
		return rv;
	}

}

@synpredgate{
	state.backtracking == 0 || !nested_type_id_stack.empty()
}

@rulecatch{
catch (RecognitionException re) {
	reportError(re);
	recover(input,re);
	retval.tree = (Object)adaptor.errorNode(input, retval.start, input.LT(-1), re);
	if(!Class_stack.empty()){
		current_scope = current_scope.getParentScope();
		current_scope.removeNestedType($Class::className);
		throw re;
	}
}
}

translation_unit
	: external_declaration+
	;

/** Either a function definition or any other kind of C decl/def.
 *  The LL(*) analysis algorithm fails to deal with this due to
 *  recursion in the declarator rules.  I'm putting in a
 *  manual predicate here so that we don't backtrack over
 *  the entire function.  Further, you get a better error
 *  as errors within the function itself don't make it fail
 *  to predict that it's a function.  Weird errors previously.
 *  Remember: the goal is to avoid backtrack like the plague
 *  because it makes debugging, actions, and errors harder.
 *
 *  Note that k=1 results in a much smaller predictor for the 
 *  fixed lookahead; k=2 made a few extra thousand lines. ;)
 *  I'll have to optimize that in the future.
 */
external_declaration
options {k=1;}
	: namespace_definition 
	|(type_specifier nested_type_id '::' declarator '{') => extern_method_definition
	|( declaration_specifiers? declarator '{' )=> function_definition
	|declaration
	;
	
namespace_definition
	: 'namespace' IDENTIFIER {NameSpaces.add($IDENTIFIER.text);}'{' external_declaration*  '}'
	;
	
extern_method_definition
	: type_specifier nested_type_id '::' declarator compound_statement
	;

function_definition
	:	declaration_specifiers? declarator compound_statement		// ANSI style only
	;

declaration
scope {
  boolean isTypedef;
}
@init {
  $declaration::isTypedef = false;
}
	: 'typedef' declaration_specifiers? {$declaration::isTypedef=true;}
	  init_declarator_list ';' // special case, looking for typedef	
	| declaration_specifiers init_declarator_list? ';' -> ^(DECLARATION declaration_specifiers init_declarator_list?)
	| template_declaration
	;
	
template_declaration
	:  template_specifier declarator
	;
	
template_specifier 
	: nested_template_id '<' template_parameter_list '>'
	;
	
nested_template_id
	: nested_type_id '::' template_type_id
	| template_type_id
	;
	
template_parameter_list
options{k = 2;}
	: template_specifier
	| type_specifier ','? template_parameter_list
	| type_specifier
	;
	
template_type_id
	: {isTemplateType(input.LT(1).getText())}? => IDENTIFIER
	;	

declaration_specifiers
	:   (    storage_class_specifier
        	|   type_qualifier
        	|   type_specifier
            )+ -> ^(DECL_SPEC ^(STORAGE_CLASS_SPEC storage_class_specifier*)? 
            		      ^(TYPE_QUAL type_qualifier*)? 
            		      ^(TYPE_SPEC type_specifier*)?)
	;
	
function_specifier
	: 'virtual' {$Class::isVirtual = true;}
	| 'explicit'
	;

init_declarator_list
	: init_declarator (',' init_declarator)*
	;

init_declarator
	: declarator ('='^ initializer)?
	;

storage_class_specifier
	: 'extern'
	| 'static'
	| 'auto'
	| 'register'
	; 

type_specifier
	: 'void'
	| 'char'
	| 'short'
	| 'int'
	| 'long'
	| 'float'
	| 'double'
	| 'signed'		//this is the deafault, isn't it ?
	| 'unsigned'
	| struct_union_or_class_specifier
	| enum_specifier
	| nested_type_id
	| nested_template_id
	;

nested_type_id returns [Types t]
scope{
  ArrayList<String> types;
}
@init{
  $nested_type_id::types = new ArrayList<String>();
}
	: global_scope = '::'? type_id scope_resolution* {isTypeName($nested_type_id::types, global_scope != null ? true : false)}?
							 {$t = getTypeName($nested_type_id::types, global_scope != null ? true : false);}
							 -> {global_scope != null}? ^(NESTED_ID_GLOBAL type_id scope_resolution*)
							 -> ^(NESTED_ID type_id scope_resolution*)
	;

scope_resolution
	: '::'! type_id
	;


struct_union_or_class_specifier
options {k=3;}
scope Class;
@init {
  paraphrases.clear();
  $Class::inClass = true;
  $Class::className = input.LT(2).getText();
  $Class::isVirtual = false;
  $Class::isTypedef = false;
  $Class::token3 = input.LT(3).getText();
  $Class::superClasses = new ArrayList<Types> ();
}
@after{
  current_scope = current_scope.getParentScope();
}
	: /*{!$Class::token3.equals(":")}? {!$Class::token3.equals("{")}?*/ struct_union_or_class IDENTIFIER {if(current_scope.isLocalType($Class::className))
													  	throw new RecognitionException();
													  Types newScope = new Types($Class::className, current_scope, access);
													  current_scope.addNestedType(newScope);
													  current_scope = newScope;}
	| {if(current_scope.isLocalType($Class::className))
		throw new RecognitionException();
	   Types newScope = new Types($Class::className, current_scope, access);
  	   current_scope.addNestedType(newScope);
  	   current_scope = newScope;}
  	   struct_union_or_class IDENTIFIER (':' 'public' n1 = nested_type_id {$Class::superClasses.add($n1.t);}  (',' n2 = nested_type_id {$Class::superClasses.add($n2.t);})*)? 
  	   {
  	   	if($Class::superClasses != null){
  	   		for(Types t : $Class::superClasses)
  	   			current_scope.addSuperType(t);
  	   	}
  	   }
  	   '{' class_declaration_list '}'
	//anonymous class ---> | struct_union_or_class  (':' 'public' nested_type_id (',' nested_type_id)*)? '{' class_declaration_list '}'
	; 
	
type_id
    : IDENTIFIER {$nested_type_id::types.add($IDENTIFIER.text);}
    //|  {}? {}? => IDENTIFIER
    ;
//    	{System.out.println($IDENTIFIER.text+" is a type");}


struct_union_or_class
	: 'struct'
	| 'union'
	| 'class'
	;

access_specifier
	: 'private'   {access = 1;}
	| 'protected' {access = 2;} 
	| 'public'    {access = 3;}
	;

class_declaration_list
scope{
  int prev_access;
}
@init{
  
    $class_declaration_list::prev_access = access;
  
}
@after{
  
    access = $class_declaration_list::prev_access;
  
}
	: class_content_element*
	;
	
class_content_element
	: access_specifier ':'
	| (specifier_qualifier_list declarator '{') => inclass_function_definition 
	| in_class_declaration
	;

constructor_definition
	: className '(' parameter_type_list? ')' compound_statement
	;
	
constructor_declaration
	: className '(' parameter_type_list? ')' ';'
	;
	
destructor_definition
	: '~'className '(' ')' compound_statement
	;
	
destructor_declaration
	: '~'className '(' ')' ';'
	;
	
className
	: IDENTIFIER {$Class::inClass == true}? {className($IDENTIFIER.text)}?
	;

in_class_declaration
@after{
	$Class::isVirtual = false;
	$Class::isTypedef = false;
	$Class::isPureVirtual = false;
}
	:  specifier_qualifier_list class_declarator_list? ';'
	|  template_declaration
	| 'typedef' specifier_qualifier_list? {$Class::isTypedef=true;}
	   init_declarator_list ';'
	| (constructor_definition | constructor_declaration)
	| (destructor_definition | destructor_declaration)
	;
	
inclass_function_definition
	: {$Class::isPureVirtual == false}? => specifier_qualifier_list declarator compound_statement
	;

specifier_qualifier_list
	: (storage_class_specifier
           |   type_qualifier
           |   function_specifier
           |   type_specifier
           |   'friend')+
	;

class_declarator_list
	: class_declarator (',' class_declarator)*
	;

class_declarator
	: declarator (':' constant_expression)?
	| ':' constant_expression
	;

enum_specifier
options {k=3;}
	: 'enum' '{' enumerator_list '}'
	| 'enum' IDENTIFIER '{' enumerator_list '}'
	| 'enum' IDENTIFIER
	;

enumerator_list
	: enumerator (',' enumerator)*
	;

enumerator
	: IDENTIFIER ('=' constant_expression)?
	;

type_qualifier
	: 'const'
	| 'volatile'
	;

declarator returns [boolean isPointer]
	: p = pointer? {if(p != null) $isPointer = true;
			else $isPointer = false;} direct_declarator -> {p != null}? ^(POINTER_DECL pointer direct_declarator)
					 			    -> direct_declarator
	| pointer -> ^(POINTER pointer)
	;

direct_declarator
	:   ( IDENTIFIER
			//{
			//if ($declaration.size()>0&& ($declaration::isTypedef)) {
			//	$Symbols::types.add($IDENTIFIER.text);
			//	System.out.println("define type "+$IDENTIFIER.text);
			//}
			//}
		|	'(' decl = declarator ')'
		)
        	declarator_suffix*  -> {decl != null}? ^(P_DECLARATOR declarator ^(DECL_SUF declarator_suffix*)?)
        			    -> ^(DECLARATOR IDENTIFIER ^(DECL_SUF declarator_suffix*)?)
	;

declarator_suffix
	:'[' constant_expression ']'				-> ^(ARRAY_CONST_DECL constant_expression)
    	|'[' ']'						-> ^(ARRAY_DECL)
    	|'(' parameter_type_list? ')' const_method_specifier? pure_virt_method_specifier?
    								->^(PARAM_LIST parameter_type_list? const_method_specifier? pure_virt_method_specifier?)
    	|'(' identifier_list? ')'									//maybe K&R style
    	//|'(' ')' const_method_specifier? pure_virt_method_specifier? == rule3 with parameter_type_list?
	;
	
const_method_specifier
	: {!Class_stack.empty()}? {$Class::inClass}? 'const'
	;
	
pure_virt_method_specifier
	: {!Class_stack.empty()}? {$Class::inClass}? {$Class::isVirtual}? ('=' '0') {$Class::isPureVirtual = true;}
	;

pointer
	: '*' type_qualifier+ pointer? -> ^(QUAL_POINTER type_qualifier+ pointer?)
	| '*' pointer -> ^(POINTER pointer)
	| '*' -> POINTER
	;

parameter_type_list
	: parameter_list (','! '...'! {((CommonTree)$parameter_list.tree).addChild(new CommonTree(new CommonToken(Token.DOWN, "VAR_ARGS")));})? 
	;

parameter_list
	: params += parameter_declaration (',' params += parameter_declaration)* -> {createTreeFromList($params)}
	;

parameter_declaration
	: declaration_specifiers (declarators += declarator| declarators += abstract_declarator)* -> ^(PARAM declaration_specifiers {createTreeFromList($declarators)})
	;

identifier_list
	: IDENTIFIER (',' IDENTIFIER)*
	;

type_name
	: specifier_qualifier_list abstract_declarator?
	;

abstract_declarator
	: pointer direct_abstract_declarator?  -> ^(POINTER_DECL pointer direct_abstract_declarator?)
	| direct_abstract_declarator -> direct_abstract_declarator
	;

direct_abstract_declarator
	:	( '(' par_decl = abstract_declarator ')' | decl_suf = abstract_declarator_suffix ) decl_suffixes += abstract_declarator_suffix*
		
		-> {par_decl != null}? ^(P_ABS_DECLARATOR abstract_declarator abstract_declarator_suffix*)
		-> ^(ABS_DECLARATOR $decl_suf {createTreeFromList($decl_suffixes)})
	;

abstract_declarator_suffix
	:	'[' ']'				-> ^(ARRAY_DECL)
	|	'[' constant_expression ']'	-> ^(ARRAY_CONST_DECL constant_expression)
	//|	'(' ')'		     \>
	|	'(' parameter_type_list? ')'	-> ^(PARAM_LIST parameter_type_list)
	;
	
initializer
	: assignment_expression
	| '{' initializer_list ','? '}'
	;

initializer_list
	: initializer (',' initializer)*
	;

// E x p r e s s i o n s

argument_expression_list
	:   assignment_expression (',' assignment_expression)*
	;

additive_expression
	: (multiplicative_expression) ('+' multiplicative_expression | '-' multiplicative_expression)*
	;

multiplicative_expression
	: (cast_expression) ('*' cast_expression | '/' cast_expression | '%' cast_expression)*
	;

cast_expression
	: '(' type_name ')' cast_expression
	| unary_expression
	;

unary_expression
	: postfix_expression
	| '++' unary_expression
	| '--' unary_expression
	| unary_operator cast_expression
	| 'sizeof' unary_expression
	| 'sizeof' '(' type_name ')'
	;

postfix_expression
	:   primary_expression
        (   '[' expression ']'
        |   '(' ')'
        |   '(' argument_expression_list ')'
        |   '.' IDENTIFIER
        |   '->' IDENTIFIER
        |   '++'
        |   '--'
        )*
	;

unary_operator
	: '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

primary_expression
	: IDENTIFIER
	| constant
	| 'this'
	| '(' expression ')'
	;

constant
 //options{greedy = true;}
    :   (ZERO | DECIMAL_LITERAL)
    |   HEX_LITERAL
    |   OCTAL_LITERAL
    |	CHARACTER_LITERAL
    |	STRING_LITERAL
    |   FLOATING_POINT_LITERAL
    ;

/////

expression
	: assignment_expression (',' assignment_expression)*
	;

constant_expression
	: conditional_expression
	;

assignment_expression
	: lvalue assignment_operator assignment_expression -> ^(assignment_expression lvalue assignment_expression)
	| conditional_expression
	| new_exp
	;
new_exp
	: 'new' nested_type_id ('('argument_expression_list?')')?
	;

	
lvalue
	:	unary_expression
	;

assignment_operator
	: '='
	| '*='
	| '/='
	| '%='
	| '+='
	| '-='
	| '<<='
	| '>>='
	| '&='
	| '^='
	| '|='
	;

conditional_expression
	: logical_or_expression ('?' expression ':' conditional_expression)?
	;

logical_or_expression
	: logical_and_expression ('||' logical_and_expression)*
	;

logical_and_expression
	: inclusive_or_expression ('&&' inclusive_or_expression)*
	;

inclusive_or_expression
	: exclusive_or_expression ('|' exclusive_or_expression)*
	;

exclusive_or_expression
	: and_expression ('^' and_expression)*
	;

and_expression
	: equality_expression ('&' equality_expression)*
	;
equality_expression
	: relational_expression (('=='|'!=') relational_expression)*
	;

relational_expression
	: shift_expression (('<'|'>'|'<='|'>=') shift_expression)*
	;

shift_expression
	: additive_expression (('<<'|'>>') additive_expression)*
	;

// S t a t e m e n t s

statement
	: labeled_statement
	| compound_statement
	| expression_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	;

labeled_statement
	: IDENTIFIER ':' statement
	| 'case' constant_expression ':' statement
	| 'default' ':' statement
	;

compound_statement
	: '{' (declaration | statement)* '}'				//not only at the begining
	;

statement_list
	: statement+
	;

expression_statement
	: ';'
	| expression ';'
	;

selection_statement
	: 'if' '(' expression ')' statement (options {k=1; backtrack=false;}:'else' statement)?
	| 'switch' '(' expression ')' statement
	;

iteration_statement
	: 'while' '(' expression ')' statement
	| 'do' statement 'while' '(' expression ')' ';'
	| 'for' '(' (expression_statement | simple_declaration) expression_statement expression? ')' statement
	;
	
simple_declaration 
	: type_specifier init_declarator_list ';'
	;

jump_statement
	: 'goto' IDENTIFIER ';'
	| 'continue' ';'
	| 'break' ';'
	| 'return' ';'
	| 'return' expression ';'
	;

IDENTIFIER
	:	LETTER (LETTER|'0'..'9')*
	;
	
fragment
LETTER
	:	'$'
	|	'A'..'Z'
	|	'a'..'z'
	|	'_'
	;

CHARACTER_LITERAL
    :   '\'' ( EscapeSequence | ~('\''|'\\') ) '\''
    ;

STRING_LITERAL
    :  '"' ( EscapeSequence | ~('\\'|'"') )* '"'
    ;

HEX_LITERAL : '0' ('x'|'X') HexDigit+ IntegerTypeSuffix?;


ZERO 	: '0';

DECIMAL_LITERAL : ('0'  | ('1'..'9') ('0'..'9')*) IntegerTypeSuffix?;

OCTAL_LITERAL : '0' ('0'..'7')+ IntegerTypeSuffix?;

fragment
HexDigit : ('0'..'9'|'a'..'f'|'A'..'F') ;

fragment
IntegerTypeSuffix
options{greedy=true;}
	:	('u' | 'U')? ('l' | 'L')
	|	('u' | 'U') ('l' | 'L')?
	;

FLOATING_POINT_LITERAL
options{greedy = true;}
    :   ('0'..'9')+ '.' ('0'..'9')* Exponent? FloatTypeSuffix?
    |   '.' ('0'..'9')+ Exponent? FloatTypeSuffix?
    |   ('0'..'9')+ Exponent FloatTypeSuffix?
    |   ('0'..'9')+ Exponent? FloatTypeSuffix
	;

fragment
Exponent : ('e'|'E') ('+'|'-')? ('0'..'9')+ ;

fragment
FloatTypeSuffix : ('f'|'F'|'d'|'D') ;

fragment
EscapeSequence
    :   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
    |   OctalEscape
    ;

fragment
OctalEscape
    :   '\\' ('0'..'3') ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7')
    ;

fragment
UnicodeEscape
    :   '\\' 'u' HexDigit HexDigit HexDigit HexDigit
    ;

WS  :  (' '|'\r'|'\t'|'\u000C'|'\n') {$channel=HIDDEN;}
    ;

COMMENT
    :   '/*' ( options {greedy=false;} : . )* '*/' {$channel=HIDDEN;}
    ;

LINE_COMMENT
    : '//' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    ;

// ignore #line info for now
LINE_COMMAND 
    : '#' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    ;
