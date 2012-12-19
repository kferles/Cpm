tree grammar ResolveIdentifiers;

options{
  tokenVocab = Cpm;
  ASTLabelType=CommonTree;
}

@header{
import treeNodes4antlr.*;
}


translation_unit
	: external_declaration+
	;

external_declaration
	: declaration
	;
	
declaration
	: line_marker
	;

init_declarator_list
   	: ^(DECLARATION_LIST init_declarator+)
   	;

init_declarator
   : ^(DECLARATION declarator)
   			{ 
   			  DeclarationToken node = (DeclarationToken) $DECLARATION.getToken();
   			  String id = $declarator.id;
   			  System.out.println(node.getDeclType().toString(id));
   			}
     | ^(DECLARATION ^('=' declarator initializer))
   //| ^(DECL ^('=' declarator initializer))
   ;
   
initializer
	: assignment_expression
	;
	
assignment_expression
	: ^(assignment_operator lvalue assignment_expression)
	| conditional_expression
	;

conditional_expression
	: ^('?' logical_or_expression ^(':' expression conditional_expression))
	| logical_or_expression
	;

logical_or_expression
	: logical_and_expression
	| ^('||' logical_and_expression logical_and_expression)
	;

logical_and_expression
	: inclusive_or_expression
	| ^('&&' inclusive_or_expression inclusive_or_expression)
	;

inclusive_or_expression
	: exclusive_or_expression
	| ^('|' exclusive_or_expression exclusive_or_expression)
	;

exclusive_or_expression
	: and_expression
	| ^('^' and_expression and_expression)
	;

and_expression
	: equality_expression
	| ^('&' equality_expression equality_expression)
	;

equality_expression
	: relational_expression
	| ^(('=='|'!=') relational_expression relational_expression)
	;
	
relational_expression
	: shift_expression
	| ^(('<'|'>'|'<='|'>=') shift_expression shift_expression)
	;

shift_expression
	: additive_expression
	| ^(('<<' | '>>') additive_expression additive_expression)
	;

additive_expression
	: multiplicative_expression
	| ^(('+' | '-') multiplicative_expression multiplicative_expression)
	;

multiplicative_expression
	: cast_expression
	| ^(('*' | '%' | '/') cast_expression cast_expression)
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

lvalue
    : unary_expression	
    ;

unary_expression
	: postfix_expression
	| '++' unary_expression
	| '--' unary_expression
	| unary_operator cast_expression
	| 'sizeof' '(' type_name ')'
	| 'sizeof' unary_expression
	;

postfix_expression
	: primary_expression
	(
	  ^(INDEX postfix_expression expression)
	| ^(CALL postfix_expression argument_expression_list?)
	| ^(OBJ_ACCESS postfix_expression nested_name_id)
	| ^(PTR_ACCESS postfix_expression nested_name_id)
	| ^(INCR_POSTFIX postfix_expression)
	| ^(DECR_POSTFIX postfix_expression)
	)
	;

argument_expression_list
	: assignment_expression (',' assignment_expression)*
	;

cast_expression
	: '(' type_name ')' cast_expression
	| unary_expression
	;

primary_expression
	: constant
	| nested_name_id
	| 'this'
	| '(' expression ')'
	;
	
nested_name_id
	: ^('::' id scope_resolution*)
	| ^(id scope_resolution*)
	;

scope_resolution
	: '::' id
	;
	
expression
	: assignment_expression (',' assignment_expression)*
	;


unary_operator
	: '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

id
  : template_id
  | name_id
  ;

name_id
  : IDENTIFIER	
  ;

template_id
	: IDENTIFIER '<' template_argument_list '>'
	;

template_argument_list
	: template_argument ',' template_argument_list
	| template_argument
	;

template_argument
	: type_name
	;

type_name
	: //specifier_qualifier_list abstract_declarator?
	;

declarator returns [String id]
	: IDENTIFIER {$id = $IDENTIFIER.text;}
	;


constant
    :   HEX_LITERAL
    |   OCTAL_LITERAL
    |   DECIMAL_LITERAL
    |	CHARACTER_LITERAL
    |	STRING_LITERAL
    |   FLOATING_POINT_LITERAL
    ;

line_marker
	: ^(LINE_MARKER DECIMAL_LITERAL STRING_LITERAL line_marker_flags?)
	;
	
line_marker_flags
	: ^(DECIMAL_LITERAL line_marker_flags)
	| DECIMAL_LITERAL
	;
