%{  

	#include <stdlib.h>
	#include <pthread.h>
	#include <stdio.h>
	#include <math.h>
	#include <limits.h>
	#include <stdlib.h>

	int q = 0;
	char* answer;
	
	void* IM_exec(void* a);
	void* RF1_exec(void* a);
	void* ALU_exec(void* a);
	void* DM_exec(void* a);
	void* RF2_exec(void* a);
	void* update(void* a);
	
	char* hextobin(char* hex);
	long int binar(char*x, int n);
	char* substri(char* in,int i,int j);
	long boolnoter(long num1);
	long boolorer(long num1, long num2);
	long boolander(long num1, long num2);

	long int memory[1024 * 1024 * 16];
	long int registers[32];
	char* instr_array[1000];
	long int break_pc[1000];
	int br=0;		
	//instruction
	char* instruction_IM;
	char* instruction_RF1;
	char* instruction_ALU;
	int breakval=0;
	int continueval=0;
	//PC
	long int PC_IM = 0, PC_RF1 = 0, PC_ALU = 0, PC_DM = 0;
	
	//contents read from the register file
	long int regread1_RF1 = 0, regread2_RF1 = 0, regread1_ALU = 0, regread2_ALU = 0, regread2_DM = 0;
	
	//immediate contnents
	long int immediate_RF1 = 0, immediate_ALU = 0;
	
	//ALU signals
	long int ALUinput1_ALU = 0, ALUinput2_ALU = 0, ALUoutput_ALU = 0, ALUoutput_DM = 0, ALUoutput_RF2 = 0;
	
	//Register destinations
	int regdst1_RF1 = 0, regdst2_RF1 = 0, regdst1_ALU = 0, regdst2_ALU = 0, regdst_ALU = 0, regdst_DM = 0, regdst_RF2 = 0;
	
	//Data from memory
	long int memData_DM  = 0, memData_RF2 = 0;
	
	//LO and HI
	long int LO = 0, HI = 0;

	//register addresses
	int regread1 = 0, regread2 = 0;
	
	//control signals
	int regWrite_RF1 = 0, regWrite_ALU = 0, regWrite_DM = 0, regWrite_RF2 = 0;
	int memToReg_RF1 = 0, memToReg_ALU = 0, memToReg_DM = 0, memToReg_RF2 = 0;
	int memRead_RF1 = 0, memRead_ALU = 0, memRead_DM = 0;
	int memWrite_RF1 = 0, memWrite_ALU = 0, memWrite_DM = 0;
	int ALUsrc_RF1 = 0, ALUsrc_ALU = 0;
	int regDst_RF1 = 0, regDst_ALU = 0;
	int PCSrc_IM = 0, PCSrc_DM = 0;
	int Zero_ALU = 0, Zero_DM = 0;
	int M_RF1 = 0, M_ALU = 0, M_DM = 0;
	int byte_RF1 = 0, byte_ALU = 0, byte_DM = 0;

	//forwarding path p1
	int p1_1 = 0, p1_2 = 0;
	long int p1_1_data = 0, p1_2_data = 0;

	//forwarding path p2
	int p21_1 = 0, p21_2 = 0;
	long int p21_1_data = 0, p21_2_data = 0;
	int p22_1 = 0, p22_2 = 0;
	long int p22_1_data = 0, p22_2_data = 0;
	
	//forwarding path p3
	int p3 = 0;
	long int p3_data = 0;
	
	int flag = 0;
	int rflag=0;

	int r1_ALU = 0, r2_ALU = 0;
	int contains ( long int a)
	{
	for ( int k1 = 0; k1 < br ; k1++)
	{
	//	printf ("%ld %ld\n",break_pc[k1],a);
		if ( break_pc[k1]==a)
			return 1;
	}
	return  0;
	}

%}

%X COMM 


%%

[0-9A-Fa-f]{8} { q++; BEGIN COMM;}

<COMM>\n {BEGIN 0;}

<COMM><<EOF>> {BEGIN 0;}

\n		{q++; /*//12456*/}
EOF		{q++; /*//12456*/}
.*		{}

%%

int main(int argc, char *argv[]){

	int *a;
	char* input1;
	
	if(argv[1] == NULL){
		printf("No input file specified\n");
		exit(-1);
	}
	yyin = fopen(argv[1], "r");

	yylex();
	
	fclose(yyin);

	for(int i = 0; i < q; i++){
		instr_array[i] = (char*)malloc(9*sizeof(char));
	}
	
	FILE* in_file = fopen(argv[1], "r");
	
	int i = 0;
	while(fscanf(in_file, "%s", instr_array[i]) > 0){
		i++;
	}
	
	fclose(in_file);
	
	instruction_IM = (char*)malloc(33*sizeof(char));
	instruction_RF1 = (char*)malloc(33*sizeof(char));
	instruction_ALU = (char*)malloc(33*sizeof(char));
	instruction_IM = "11111111111111111111111111111111";
	instruction_RF1 = "11111111111111111111111111111111";
	instruction_ALU	 = "11111111111111111111111111111111";
	
	for(int j = 0; j < 32; j++){
		registers[j] = 0;
	}
	for(int j = 0 ; j < 1024; j++){
		memory[j] = 0;
	}
xw1:	rflag=0;
	scanf("%s",input1);
	if(strcmp(input1, "regdump") == 0){
		for(int k = 0; k < 16; k++){
			printf("register %d: %ld\n", k, registers[k]);
		}
	}
	else if(strcmp(input1,"step")==0){goto xw2; }
	else if(strcmp(input1,"run")==0){breakval=1; }
	else if(strcmp(input1,"continue")==0){continueval=1; }
	else if (strcmp(input1,"break")==0)
	{
	long int rg=0;
	if (scanf("%ld",&rg)==1)
	{				
		if(br<1000)
		{
			break_pc[br++]=rg;
		}				
	}
	goto xw1;
	}
	else if (strcmp(input,"delete")==0)
	{
		long int rg=0;
		if (scanf("%ld",&rg)==1)
		{
			for (int b1 =0 ; b1<br;b1++)
			{
				if(break_pc[b1]==rg)
					break_pc[b1]=0;
			}
		}
	goto xw1;
	}
	else
	{goto xw1;}
xw2:	rflag=0;
	pthread_t IM;
	pthread_t RF1;
	pthread_t ALU;
	pthread_t DM;
	pthread_t RF2;
	pthread_t upd;	
	void* a1;
	void* a2;
	void* a3;
	void* a4;
	void* a5;
	void* a6;
	
	i = 1;

	printf("cycle 1\n");
	pthread_create(&IM, NULL, IM_exec, (void*)&a);
	pthread_join(IM, &a1);	
	
	pthread_create(&upd, NULL, &update, (void*)&a);
	pthread_join(upd, &a6); 
	i++;
	if(breakval==1){goto xw4;}
	if(continueval==1 && !contains(PC_ALU)){printf("hahaha\n");goto xw4;}
	else if(continueval==1 && contains(PC_ALU)){continueval=0;}
xw3:	scanf("%s",input1);
	if(strcmp(input1, "regdump") == 0){
		for(int k = 0; k < 16; k++){
			printf("register %d: %ld\n", k, registers[k]);
		}
	}

	else if(strcmp(input1,"step")==0){goto xw4; }
	else if(strcmp(input1,"run")==0){breakval=1; }
	else if(strcmp(input1,"continue")==0){continueval=1; }
	else if (strcmp(input1,"break")==0)
	{
	long int rg=0;
	if (scanf("%ld",&rg)==1)
	{				
		if(br<1000)
		{
			break_pc[br++]=rg;
		}				
	}
	
	}
	else if (strcmp(input1,"break")==0)
	{
	long int rg=0;
	if (scanf("%ld",&rg)==1)
	{				
		if(br<1000)
		{
			break_pc[br++]=rg;
		}				
	}
	goto xw3;
	}
	else if (strcmp(input,"delete")==0)
	{
		long int rg=0;
		if (scanf("%ld",&rg)==1)
		{
			for (int b1 =0 ; b1<br;b1++)
			{
				if(break_pc[b1]==rg)
					break_pc[b1]=0;
			}
		}
	goto xw3;	
	}
	else
	{goto xw3;}
xw4:	rflag=0;
	printf("cycle 2\n");
	pthread_create(&IM, NULL, IM_exec, (void*)&a);
	pthread_create(&RF1, NULL, RF1_exec, (void*)&a);
	pthread_join(IM, &a1);
	pthread_join(RF1, &a2);
	
	pthread_create(&upd, NULL, &update, (void*)&a);
	pthread_join(upd, &a6);
	i++;
	if(breakval==1){goto xw6;}	
	if(continueval==1 && !contains(PC_ALU)){goto xw6;}
	else if(continueval==1 && contains(PC_ALU)){continueval=0;}
xw5:	scanf("%s",input1);
	if(strcmp(input1, "regdump") == 0){
		for(int k = 0; k < 16; k++){
			printf("register %d: %ld\n", k, registers[k]);
		}
	}
	else if(strcmp(input1,"step")==0){goto xw6; }
	else if(strcmp(input1,"run")==0){breakval=1; }
	else if(strcmp(input1,"continue")==0){continueval=1; }
	else if (strcmp(input1,"break")==0)
	{
	long int rg=0;
	if (scanf("%ld",&rg)==1)
	{				
		if(br<1000)
		{
			break_pc[br++]=rg;
		}				
	}
	
	}
	else if (strcmp(input1,"break")==0)
	{
	long int rg=0;
	if (scanf("%ld",&rg)==1)
	{				
		if(br<1000)
		{
			break_pc[br++]=rg;
		}				
	}
	goto xw5;
	}
	else if (strcmp(input,"delete")==0)
	{
		long int rg=0;
		if (scanf("%ld",&rg)==1)
		{
			for (int b1 =0 ; b1<br;b1++)
			{
				if(break_pc[b1]==rg)
					break_pc[b1]=0;
			}
		}
	goto xw5;	
	}
	else
	{goto xw5;}
xw6:	rflag=0;
	printf("cycle 3\n");
	pthread_create(&IM, NULL, IM_exec, (void*)&a);
	pthread_create(&RF1, NULL, RF1_exec, (void*)&a);
	pthread_create(&ALU, NULL, ALU_exec, (void*)&a);
	pthread_join(IM, &a1);
	pthread_join(RF1, &a2);	
	pthread_join(ALU, &a3);
	
	pthread_create(&upd, NULL, &update, (void*)&a);
	pthread_join(upd, &a6);
	i++;
	if(breakval==1){goto xw8;}
	if(continueval==1 && !contains(PC_ALU)){goto xw8;}
	else if(continueval==1 && contains(PC_ALU)){continueval=0;}
xw7:	scanf("%s",input1);
	if(strcmp(input1, "regdump") == 0){
		for(int k = 0; k < 16; k++){
			printf("register %d: %ld\n", k, registers[k]);
		}
	}
	else if(strcmp(input1,"step")==0){goto xw8; }
	else if(strcmp(input1,"run")==0){breakval=1; }
	else if(strcmp(input1,"continue")==0){continueval=1; }
	else if (strcmp(input1,"break")==0)
	{
	long int rg=0;
	if (scanf("%ld",&rg)==1)
	{				
		if(br<1000)
		{
			break_pc[br++]=rg;
		}				
	}
	
	}
	else if (strcmp(input1,"break")==0)
	{
	long int rg=0;
	if (scanf("%ld",&rg)==1)
	{				
		if(br<1000)
		{
			break_pc[br++]=rg;
		}				
	}
	goto xw7;
	}
	else if (strcmp(input,"delete")==0)
	{
		long int rg=0;
		if (scanf("%ld",&rg)==1)
		{
			for (int b1 =0 ; b1<br;b1++)
			{
				if(break_pc[b1]==rg)
					break_pc[b1]=0;
			}
		}
	goto xw7;
	}
	else
	{goto xw7;}
xw8:	rflag=0;
	printf("cycle 4\n");	
	pthread_create(&IM, NULL, IM_exec, (void*)&a);
	pthread_create(&RF1, NULL, RF1_exec, (void*)&a);
	pthread_create(&ALU, NULL, ALU_exec, (void*)&a);
	pthread_create(&DM, NULL, DM_exec, (void*)&a);
	pthread_join(IM, &a1);
	pthread_join(RF1, &a2);	
	pthread_join(ALU, &a3);
	pthread_join(DM, &a4);
	
	pthread_create(&upd, NULL, &update, (void*)&a);
	pthread_join(upd, &a6);
	i++;
	if(breakval==1){goto xw10;}	
	if(continueval==1 && !contains(PC_ALU)){goto xw10;}
	else if(continueval==1 && contains(PC_ALU)){continueval=0;}	
xw9:	scanf("%s",input1);
	if(strcmp(input1, "regdump") == 0){
		for(int k = 0; k < 16; k++){
			printf("register %d: %ld\n", k, registers[k]);
		}
	}
	else if(strcmp(input1,"step")==0){goto xw10; }
	else if(strcmp(input1,"run")==0){breakval=1; }
	else if(strcmp(input1,"continue")==0){continueval=1; }
	else if (strcmp(input1,"break")==0)
	{
	long int rg=0;
	if (scanf("%ld",&rg)==1)
	{				
		if(br<1000)
		{
			break_pc[br++]=rg;
		}				
	}
	
	}
	else if (strcmp(input1,"break")==0)
	{
	long int rg=0;
	if (scanf("%ld",&rg)==1)
	{				
		if(br<1000)
		{
			break_pc[br++]=rg;
		}				
	}
	goto xw9;
	}
	else if (strcmp(input,"delete")==0)
	{
		long int rg=0;
		if (scanf("%ld",&rg)==1)
		{
			for (int b1 =0 ; b1<br;b1++)
			{
				if(break_pc[b1]==rg)
					break_pc[b1]=0;
			}
		}
	goto xw9;
	}
	else
	{goto xw9;}
xw10:	rflag=0;
	while(PC_IM < q + 4){
			
		printf("cycle %d\n", i);
		i++;
		
		pthread_create(&IM, NULL, IM_exec, (void*)&a);
		pthread_create(&RF1, NULL, RF1_exec, (void*)&a);
		pthread_create(&ALU, NULL, ALU_exec, (void*)&a);
		pthread_create(&DM, NULL, DM_exec, (void*)&a);
		pthread_create(&RF2, NULL, RF2_exec, (void*)&a);
		pthread_join(IM, &a1);
		pthread_join(RF1, &a2);
		pthread_join(ALU, &a3);
		pthread_join(RF2, &a4);
		pthread_join(DM, &a5);
		
		pthread_create(&upd, NULL, &update, (void*)&a);
		pthread_join(upd, &a6);
	if(breakval==1){goto xw12;}
	if(continueval==1 && !contains(PC_ALU)){goto xw12;}
	else if(continueval==1 && contains(PC_ALU)){continueval=0;}
xw11:		scanf("%s",input1);
		if(strcmp(input1, "regdump") == 0){
			for(int k = 0; k < 16; k++){
				printf("register %d: %ld\n", k, registers[k]);
			}
		}
	else if(strcmp(input1,"step")==0){goto xw12; }
	else if(strcmp(input1,"run")==0){breakval=1; }
	else if(strcmp(input1,"continue")==0){continueval=1; }
	else if (strcmp(input1,"break")==0)
	{
	long int rg=0;
	if (scanf("%ld",&rg)==1)
	{				
		if(br<1000)
		{
			break_pc[br++]=rg;
		}				
	}
	
	}
	else if (strcmp(input1,"break")==0)
	{
	long int rg=0;
	if (scanf("%ld",&rg)==1)
	{				
		if(br<1000)
		{
			break_pc[br++]=rg;
		}				
	}
	goto xw11;
	}
	else if (strcmp(input,"delete")==0)
	{
		long int rg=0;
		if (scanf("%ld",&rg)==1)
		{
			for (int b1 =0 ; b1<br;b1++)
			{
				if(break_pc[b1]==rg)
					break_pc[b1]=0;
			}
		}
	goto xw11;
	}
	else
	{goto xw11;}
xw12:	rflag=0;
	//printf("%d",PC_ALU);	
	}	
	
	pthread_exit(NULL);
	
	
	return 0;
}

void* IM_exec(void* a){
	
	if(PCSrc_IM == 1){			//Mux for program counter
		PC_IM = PC_DM;
	}

	if(PC_IM < q){
		instruction_IM = hextobin(instr_array[PC_IM]);		//Fetching instruction
	}
	else{
		instruction_IM = "11111111111111111111111111111111";
	}
	
	PC_IM++;									//PC = PC + 4
	registers[31] = PC_IM;							//The 32nd register is PC
	
	pthread_exit(NULL);
}

void* RF1_exec(void* a){
	
	regdst1_RF1 = binar(substri(instruction_RF1, 11, 16), 5);			//Inter-state register for instruction[20-16]
	regdst2_RF1 = binar(substri(instruction_RF1, 16, 21), 5);			//Inter-state register for instruction[15-11]
	
	regread1 = binar(substri(instruction_RF1, 6, 11), 5);			//Address of the first register
	regread2 = binar(substri(instruction_RF1, 11, 16), 5);		//Address of the second register
	
	ALUsrc_RF1 = 1;
	regWrite_RF1 = 1; memToReg_RF1 = 1;												
	regDst_RF1 = 0;
	immediate_RF1 = binar(substri(instruction_RF1, 16, 32), 16);
	memWrite_RF1 = 0;
	memRead_RF1 = 0;
	M_RF1 = 0;
	
	if(strcmp(substri(instruction_RF1, 0, 6),("001000")) == 0){		//ADDI
		regDst_RF1 = 0;	
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("011100")) == 0){	//MADD
		regWrite_RF1 = 0; memToReg_RF1 = 0;
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("001101")) == 0){	//ORI
		regDst_RF1 = 0;
		ALUsrc_RF1 = 1;
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("001111")) == 0){	//LUI
		regread1 = binar(substri(instruction_RF1, 11, 16), 5);
		regDst_RF1 = 0;	
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("001010")) == 0){	//SLTI
		regDst_RF1 = 0;	
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("000100")) == 0){	//BEQ
		regWrite_RF1 = 0; memToReg_RF1 = 0;
		M_RF1 = 1;
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("000001")) == 0){	//BGEZ
		regread2 = 0;
		regWrite_RF1 = 0; memToReg_RF1 = 0;
		M_RF1 = 1;
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("000111")) == 0){	//BGTZ
		regread2 = 0;
		regWrite_RF1 = 0; memToReg_RF1 = 0;
		M_RF1 = 1;
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("000110")) == 0){	//BLEZ
		regread2 = 0;
		M_RF1 = 1;
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("000001")) == 0){	//BLTZ
		regread2 = 0;
		regWrite_RF1 = 0; memToReg_RF1 = 0;
		memWrite_RF1 = 0;
		M_RF1 = 1;
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("100000")) == 0){	//LB
		immediate_RF1 = binar(substri(instruction_RF1, 16, 32), 16);
		memRead_RF1 = 1;
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("100011")) == 0){	//LW
		immediate_RF1 = binar(substri(instruction_RF1, 16, 32), 16);
		memRead_RF1 = 1;
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("101000")) == 0){	//SB
		immediate_RF1 = binar(substri(instruction_RF1, 16, 32), 16);
		regWrite_RF1 = 0; memToReg_RF1 = 0;
		memWrite_RF1 = 1;
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("101011")) == 0){	//SW
		immediate_RF1 = binar(substri(instruction_RF1, 16, 32), 16);
		regWrite_RF1 = 0; memToReg_RF1 = 0;
		memWrite_RF1 = 1;
	}
	else if(strcmp(substri(instruction_RF1, 0, 6),("000000")) == 0){		//OTHERS
		if(strcmp(substri(instruction_RF1, 26, 32),("100000")) == 0 ){	//ADD
			regDst_RF1 = 1;
			ALUsrc_RF1 = 0;
		}
		else if(strcmp(substri(instruction_RF1, 26, 32),("100010")) == 0){
			regDst_RF1 = 1;
			ALUsrc_RF1 = 0;
		}
		else if(strcmp(substri(instruction_RF1, 26, 32),("100100")) == 0){	//AND
			regDst_RF1 = 1;
			ALUsrc_RF1 = 0;
		}
		else if(strcmp(substri(instruction_RF1, 26, 32),("011000")) == 0){	//MULT
			regWrite_RF1 = 0; memToReg_RF1 = 0;
		}
		else if(strcmp(substri(instruction_RF1, 26, 32),("100111")) == 0){	//NOR
			regDst_RF1 = 1;
			memRead_RF1 = 0;
			ALUsrc_RF1 = 0;
		}
		else if(strcmp(substri(instruction_RF1, 26, 32),("100101")) == 0){	//OR
			regDst_RF1 = 1;
			ALUsrc_RF1 = 0;
		}
		else if(strcmp(substri(instruction_RF1, 26, 32),("000000")) == 0){	//SLL
			regread1 = binar(substri(instruction_RF1, 11, 16), 5);
			immediate_RF1 = binar(substri(instruction_RF1, 21, 26), 5);
			regDst_RF1 = 1;
			ALUsrc_RF1 = 1;
		}
		else if(strcmp(substri(instruction_RF1, 26, 32),("000100")) == 0){	//SLLV
			regread2 = binar(substri(instruction_RF1, 6, 11), 5);			//Address of the first register
			regread1 = binar(substri(instruction_RF1, 11, 16), 5);		//Address of the second register
			regDst_RF1 = 1;
			ALUsrc_RF1 = 0;
		}
		else if(strcmp(substri(instruction_RF1, 26, 32),("101011")) == 0){	//SLTU
			regDst_RF1 = 1;
			memRead_RF1 = 0;
			ALUsrc_RF1 = 0;
		}
		else{
			printf("%s, aleph 1: Instruction not supported\n", instruction_RF1);
			exit(-1);
		}
	}
	else if(strcmp(instruction_RF1, "11111111111111111111111111111111") == 0){
		regread1 = 0;
		regread2 = 0;
		immediate_RF1 = 0;
		regDst_RF1 = 0;
		regWrite_RF1 = 0; memToReg_RF1 = 0;							
		memWrite_RF1 = 0;				
		memRead_RF1 = 0;				
		ALUsrc_RF1 = 0;	
		M_RF1 = 0;
	}
	else{
		printf("%s, aleph2: Instruction not supported\n", instruction_RF1);
		exit(-1);
	}
	
	regread1_RF1 = registers[regread1];									//The data from the first register
	regread2_RF1 = registers[regread2];									//The data from the second register

	pthread_exit(NULL);
}

void* ALU_exec(void* a){
	
	if(regDst_ALU == 1){												//Decide the number of the register in which you will write data
		regdst_ALU = regdst2_ALU;
	}
	else regdst_ALU = regdst1_ALU;
	
	ALUinput1_ALU = regread1_ALU;

	if(ALUsrc_ALU == 1){				
		ALUinput2_ALU = immediate_ALU;
	}
	else{
		ALUinput2_ALU = regread2_ALU;
	}

	//printf("in1: %ld, in2: %ld\n", ALUinput1_ALU, ALUinput2_ALU);

	if(p1_1 == 1){
		ALUinput1_ALU = p1_1_data;
	}
	else if(p21_1 == 1){
		ALUinput1_ALU = p21_1_data;
	}
	else if(p22_1 == 1){
		ALUinput1_ALU = p22_1_data;
	}

	if(p1_2 == 1){
		ALUinput2_ALU = p1_2_data;
	}
	else if(p21_2 == 1){
		ALUinput2_ALU = p21_2_data;
	}
	else if(p22_2 == 1){
		ALUinput2_ALU = p22_2_data;
	}

	//printf("in1: %ld, in2: %ld\n", ALUinput1_ALU, ALUinput2_ALU);
	
	if(strcmp(substri(instruction_ALU, 0, 6),"001000")==0){			//ADDI
		ALUoutput_ALU = ALUinput1_ALU + ALUinput2_ALU;
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"011100")==0){		//MADD
			long long int temp = ALUinput1_ALU * ALUinput2_ALU;
			LO = ((long int)temp) % ((long int)(pow(2, 32)));
			HI = ((long int)temp) / ((long int)(pow(2, 32)));
			ALUoutput_ALU = LO;
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"001101")==0){		//ORI
		ALUoutput_ALU = boolorer(ALUinput1_ALU, ALUinput2_ALU);
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"001111")==0){		//LUI
		ALUoutput_ALU = ((int) pow(2, 16)) * ALUinput2_ALU;
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"001010")==0){		//SLTI
		if(ALUinput1_ALU < ALUinput2_ALU) ALUoutput_ALU = 1;
		else ALUoutput_ALU = 0;
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"000100")==0){		//BEQ
		if(ALUinput1_ALU == ALUinput2_ALU) Zero_ALU = 1;
		else Zero_ALU = 0;
		ALUoutput_ALU = immediate_ALU;
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"000001")==0){		//BGEZ
		if(ALUinput1_ALU >= 0) Zero_ALU = 1;
		else Zero_ALU = 0;
		ALUoutput_ALU = immediate_ALU - pow(16, 4) - pow(16, 7);
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"000111")==0){		//BGTZ
		if(ALUinput1_ALU > 0) Zero_ALU = 1;
		else Zero_ALU = 0;
		ALUoutput_ALU = immediate_ALU - pow(16, 4) - pow(16, 7);
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"000110")==0){		//BLEZ
		if(ALUinput1_ALU <= 0) Zero_ALU = 1;
		else Zero_ALU = 0;
		ALUoutput_ALU = immediate_ALU - pow(16, 4) - pow(16, 7);
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"000001")==0){		//BLTZ
		if(ALUinput1_ALU < 0) Zero_ALU = 1;
		else Zero_ALU = 0;
		ALUoutput_ALU = immediate_ALU - pow(16, 4) - pow(16, 7);
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"100000")==0){		//LB
		ALUoutput_ALU = ALUinput1_ALU + ALUinput2_ALU - pow(16, 4) - pow(16, 7);
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"100011")==0){		//LW
		ALUoutput_ALU = ALUinput1_ALU + ALUinput2_ALU - pow(16, 4) - pow(16, 7);
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"101000")==0){		//SB
		ALUoutput_ALU = ALUinput1_ALU + ALUinput2_ALU - pow(16, 4) - pow(16, 7);
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"101011")==0){		//SW
		ALUoutput_ALU = ALUinput1_ALU + ALUinput2_ALU - pow(16, 4) - pow(16, 7);
	}
	else if(strcmp(substri(instruction_ALU, 0, 6),"000000")==0){	
		if(strcmp(substri(instruction_ALU, 26, 32),"100000")==0){		//ADD
			ALUoutput_ALU = ALUinput1_ALU + ALUinput2_ALU;
		}
		else if(strcmp(substri(instruction_ALU, 26, 32),"100010")==0){	//SUB
			ALUoutput_ALU = ALUinput1_ALU - ALUinput2_ALU;
		}
		else if(strcmp(substri(instruction_ALU, 26, 32),"100100")==0){	//AND
			ALUoutput_ALU = boolander(ALUinput1_ALU, ALUinput2_ALU);
		}
		else if(strcmp(substri(instruction_ALU, 26, 32), "011000")==0){	//MULT
			long long int temp = ALUinput1_ALU * ALUinput2_ALU;
			LO = ((long int)temp) % ((long int)(pow(2, 32)));
			HI = ((long int)temp) / ((long)(pow(2, 32)));
			ALUoutput_ALU = LO;
		}
		else if(strcmp(substri(instruction_ALU, 26, 32), "100111")==0){	//NOR
			ALUoutput_ALU = boolnoter(boolorer(ALUinput1_ALU, ALUinput2_ALU));
		}
		else if(strcmp(substri(instruction_ALU, 26, 32), "100101")==0){	//OR
			ALUoutput_ALU = boolorer(ALUinput1_ALU, ALUinput2_ALU);
		}
		else if(strcmp(substri(instruction_ALU, 26, 32), "000000")==0){	//SLL
			ALUoutput_ALU = ALUinput1_ALU * pow(2, ALUinput2_ALU);
		}
		else if(strcmp(substri(instruction_ALU, 26, 32), "000100")==0){	//SLLV
			regread1_ALU = binar(substri(instruction_ALU, 6, 11), 5);
			regread2_ALU = binar(substri(instruction_ALU, 11, 16), 5);
			ALUoutput_ALU = ALUinput1_ALU * pow(2, ALUinput2_ALU);
		}
		else if(strcmp(substri(instruction_ALU, 26, 32), "101011")==0){	//SLTU
			if(ALUinput1_ALU < ALUinput2_ALU) ALUoutput_ALU = 1;
			else ALUoutput_ALU = 0;
			//printf("%ld: in1, %ld, in2, %ld: out", ALUinput1_ALU, ALUinput2_ALU, ALUoutput_ALU);
		}
		else{
			printf("aleph 3: Instruction not supported\n");
			exit(-1);
		}
	}
	else if(strcmp(instruction_ALU, "11111111111111111111111111111111") == 0){
		
	}
	else{
		exit(-1);
	}
		
	PC_ALU = PC_ALU + binar(substri(instruction_ALU, 16, 32), 16);
	
	pthread_exit(NULL);
}

void* DM_exec(void* a){

	if(M_DM == 1 && Zero_DM == 1){
		PCSrc_DM = 1;
	}
	else{
		PCSrc_DM = 0;
	}
	
	if(memWrite_DM == 1){		//st
		if(p3_data == 1){
			memory[ALUoutput_DM/4] = p3_data;
		}
		else memory[ALUoutput_DM/4] = regread2_DM;
		if(byte_DM == 1){
			if(ALUoutput_DM % 4 == 0)
				memory[ALUoutput_DM/4] = memory[ALUoutput_DM/4] % 256;
			if(ALUoutput_DM % 4 == 1)
				memory[ALUoutput_DM/4] = 256*(memory[ALUoutput_DM/4] % 256);
			if(ALUoutput_DM % 4 == 2)
				memory[ALUoutput_DM/4] = 256*256*(memory[ALUoutput_DM/4] % 256);
			if(ALUoutput_DM % 4 == 3)
				memory[ALUoutput_DM/4] = 256*256*256*(memory[ALUoutput_DM/4] % 256);
		}
	}
	
	if(memRead_DM == 1){		//ld
		memData_DM = memory[ALUoutput_DM/4];
		if(byte_DM == 1){
			if(ALUoutput_DM % 4 == 0){
				memData_DM = memData_DM % 256;
			}
			if(ALUoutput_DM % 4 == 1){
				memData_DM = (memData_DM/256) %256;
			}
			if(ALUoutput_DM % 4 == 2){
				memData_DM = (memData_DM/(256*256))%256;
			}
			if(ALUoutput_DM % 4 == 3){
				memData_DM = (memData_DM/(256*256*256))%256;
			}
		}
	}

	pthread_exit(NULL);
}

void* RF2_exec(void* a){

	if(regWrite_RF2 == 1){
		if(memToReg_RF2 == 1){
			registers[regdst_RF2] = memData_RF2;
		}
		else{
			registers[regdst_RF2] = memData_RF2;
		}
	}
	
	pthread_exit(NULL);
}

void* update(void* a){

	p1_1 = 0;
	p1_2 = 0;
	if(regWrite_ALU == 1){
		if(regdst_ALU == regread1){
			p1_1 = 1;
			p1_1_data = ALUoutput_ALU;
		}
		else p1_1 = 0;
		if(regdst_ALU == regread2 && ALUsrc_RF1 == 0){
			p1_2 = 1;
			p1_2_data = ALUoutput_ALU;
		}
		else p1_2 = 0;
	}

	p21_1 = 0;
	p21_2 = 0;
	if(memRead_DM == 1 && flag == 0){

		if(regdst_DM == r1_ALU && regWrite_ALU == 1){
			p21_1 = 1;
			p21_1_data = memData_DM;
			flag = 1;
		}
		else p21_1 = 0;
		if(regdst_ALU == r2_ALU && regWrite_ALU == 1 && ALUsrc_ALU == 0){
			p21_2 = 1;
			p21_2_data = memData_DM;
			flag = 1;
		}
		else p21_2 = 0;
	}
	if(p1_1 == 0 && p1_2 == 0 && (p21_1 != 0 || p21_2 != 0)){
		PC_IM = PC_IM - 1;
		pthread_exit(NULL);
	}
	else{
		flag = 0;
	}

	p22_1 = 0;
	p22_2 = 0;
	if(regWrite_DM == 1){
		if(regdst_DM == regread1){
			p22_1 = 1;
			p22_1_data = memData_DM;
		}
		else p22_1 = 0;
		if(regdst_DM == regread2 && ALUsrc_RF1 == 0){
			p22_2 = 1;
			p22_2_data = memData_DM;
		}
		else p22_2 = 0;
	}

	p3 = 0;
	if(regWrite_DM == 1){
		if(regread2_DM == regdst_ALU){
			p3 = 1;
			p3_data = ALUoutput_ALU;
		}
		else p3 = 0;
	}

	if(regWrite_RF2 == 1){
		if(regread1 == regdst_RF2){
			regread1_RF1 = memData_RF2;
		}
		if(regread2 == regdst_RF2){
			regread2_RF1 = memData_RF2;
		}
	}

	r1_ALU = regread1;
	r2_ALU = regread2;

	//instruction
	instruction_ALU = instruction_RF1;
	instruction_RF1 = instruction_IM;
	
	//PC
	PC_DM = PC_ALU;
	PC_ALU = PC_RF1;
	PC_RF1 = PC_IM;
	
	//contents read from the register file
	regread2_DM = regread2_ALU;
	regread2_ALU = regread2_RF1;
	regread1_ALU = regread1_RF1;
	
	//immediate contents
	immediate_ALU = immediate_RF1;
	
	//ALU output
	ALUoutput_RF2 = ALUoutput_DM;
	ALUoutput_DM = ALUoutput_ALU;
	
	//Register destinations
	regdst1_ALU = regdst1_RF1;
	regdst2_ALU = regdst2_RF1;
	
	regdst_RF2 = regdst_DM;
	regdst_DM = regdst_ALU;
	
	//data from memory
	memData_RF2 = memData_DM;
	memData_DM = ALUoutput_ALU;
	
	//control signals
	regWrite_RF2 = regWrite_DM;
	regWrite_DM = regWrite_ALU;
	regWrite_ALU = regWrite_RF1;

	memToReg_RF2 = memToReg_DM;
	memToReg_DM = memToReg_ALU;
	memToReg_ALU = memToReg_RF1;	
	
	memRead_DM = memRead_ALU;
	memRead_ALU = memRead_RF1;

	memWrite_DM = memWrite_ALU;
	memWrite_ALU = memWrite_RF1;

	ALUsrc_ALU = ALUsrc_RF1;

	regDst_ALU = regDst_RF1;

	PCSrc_IM = PCSrc_DM;
	
	Zero_DM = Zero_ALU;
	
	M_ALU = M_RF1;
	M_DM = M_ALU;
	
	byte_ALU = byte_RF1;
	byte_DM = byte_ALU;
	
	pthread_exit(NULL);	
}

long int binar(char*x, int n){
	
	int j=0;
	int k=0;
	long int t=0;

	for( j=n-1;j>=0;j--)
	{
		t+=(x[j]-'0')*pow(2,k);
		k++;
	}
	return t;
}

long int signed_binar(char*x, int n){ //12456
	
	int j=0;
	int k=0;
	long int t=0;
	t-=(x[n-1]-'0')*pow(2,k);

	for( j=n-2;j>=0;j--)
	{
		t+=(x[j]-'0')*pow(2,k);
		k++;
	}
	return t;
}

char* hextobin(char* hex){
	char* bin=(char*)malloc(64) ;
	//bin="";
    int i = 0;
    //     strcat(bin, "0000");
	//strncat(bin, "0000",4);
 
    for(i=0; i<8; i++)
    {
        switch(hex[i])
        {
            case '0':
                strcat(bin, "0000");
                break;
            case '1':
                strcat(bin, "0001");
                break;
            case '2':
                strcat(bin, "0010");
                break;
            case '3':
                strcat(bin, "0011");
                break;
            case '4':
                strcat(bin, "0100");
                break;
            case '5':
                strcat(bin, "0101");
                break;
            case '6':
                strcat(bin, "0110");
                break;
            case '7':
                strcat(bin, "0111");
                break;
            case '8':
                strcat(bin, "1000");
                break;
            case '9':
                strcat(bin, "1001");
                break;
            case 'a':
            case 'A':
                strcat(bin, "1010");
                break;
            case 'b':
            case 'B':
                strcat(bin, "1011");
                break;
            case 'c':
            case 'C':
                strcat(bin, "1100");
                break;
            case 'd':
            case 'D':
                strcat(bin, "1101");
                break;
            case 'e':
            case 'E':
                strcat(bin, "1110");
                break;
            case 'f':
            case 'F':
                strcat(bin, "1111");
                break;
            default:
       printf("Invalid hexadecimal input.");
        }
	}
	
	return bin;
}

char* substri(char*in,int i,int j){
	char* bin = (char*)malloc(33) ;
	strncpy(bin, in+i, j-i);
	return bin;
}

long boolorer(long num1,long num2){
	int a3[32],a1[32],a2[32];
	if(num1>=0){	
		a1[31]=0;
	}
	else{ 
		a1[31]=1;
		num1+=pow(2,31);
	}
	
	for(int i=0;i<=30;i++){
		a1[i]=num1%2;;
		num1/=2;
	}

	if(num2>=0){
		a2[31]=0;
	}
	else{ 
		a2[31]=1;
		num2+=pow(2,31);
	}
	for(int i=0;i<=30;i++){
		a2[i]=num2%2;;
		num2/=2;
	}

	int ander(int a,int b){
		if (!a && !b)
		return 0;
		else if(a && !b)
		return 1;
		else if (!a && b)
		return 1;
		else if(a && b)
		return 1;
	}
	long x=0;
	for(int l=1;l<=31;l++){
		x*=2;
		x+=ander(a1[31-l],a2[31-l]);
	}
	x-=ander(a1[31],a2[31])*pow(2,31);
	return x;
}

long boolander(long num1,long num2){
	int a3[32],a1[32],a2[32];
	
	if(num1>=0){
		a1[31]=0;
	}
	else{ 
		a1[31]=1;
		num1+=pow(2,31);
	}
	
	for(int i=0;i<=30;i++){
		a1[i]=num1%2;;
		num1/=2;
	}

	if(num2>=0){
		a2[31]=0;
	}
	else{ 
		a2[31]=1;
		num2+=pow(2,31);
	}
	
	for(int i=0;i<=30;i++){
		a2[i]=num2%2;;
		num2/=2;
	}
	
	int ander(int a,int b){
		if (!a && !b)
		return 0;
		else if(a && !b)
		return 0;
		else if (!a && b)
		return 0;
		else if(a && b)
		return 1;
	}
	
	long x=0;
	for(int l=1;l<=31;l++){
		x*=2;
		x+=ander(a1[31-l],a2[31-l]);
	}
	x-=ander(a1[31],a2[31])*pow(2,31);
	return x;
}

long boolnoter(long num1){
	int a3[32],a1[32];
	if(num1>=0){
		a1[31]=0;
	}
	else{ 
		a1[31]=1;
		num1+=pow(2,31);
	}
	for(int i=0;i<=30;i++){
		a1[i]=num1%2;;
		num1/=2;
	}
	
	int ander(int a){
		if (!a)
		return 1;
		else if(a)
		return 0;
	}
	
	long x=0;
	
	for(int l=1;l<=31;l++){
		x*=2;
		x+=ander(a1[31-l]);
	}
	
	x-=ander(a1[31])*pow(2,31);
	
	return x;
}
