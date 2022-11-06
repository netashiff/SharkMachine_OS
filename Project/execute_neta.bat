/*
Author: Neta Shiff
Date: October 20 2022
 */
import jdk.swing.interop.SwingInterOpUtils;

import java.io.*;
import java.util.*;

public class finish_OS_Neta {
    // Registers
    static int ACC;//Accumulator
    static int PSIAR;//Primary Storage Instruction Address Register;
    static int SAR;// Storage Address Register
    static int SDR;// Storage Data Register
    static int TMPR;//Temporary Register
    static int CSIAR;// Control Storage Instruction Address Register;
    static int IR;// Instruction Register;
    static int MIR;// Micro-instruction Register
    static String[] Memory_Main ;// MEMORY CREATES
    static int file_number;
    static int overall_time;// the time that it took to the system run, every one unit of time will be one instruction execute
    static LinkedList<PCB> Holder = new LinkedList<>();// the link list which has the programs, we use it for the multitasking time

    public static void main(String[] args) throws CloneNotSupportedException {
        System.out.println("\nWelcome to OS machine:\n");
        System.out.println("System initializing");
        Memory_Main = new String[1024];
        Initilizing_to_zero();
        System.out.println("");
        System.out.println("reading files in the folder:");
        read_files();
        // TO LOCATE THE PSIAR IN THE FIRST LINE OF THE FILES
        PSIAR =512;
        System.out.println("");
        System.out.println("running the system");
        process_run();
        System.out.println();
        print_memory();
        print_register();
        System.out.println("");
        System.out.println("The final total time is: "+ overall_time);
        System.out.println("exiting the system");
        Initilizing_to_zero();
        Memory_Main = null;// CLEAN MEMORY
        System.out.println("finish");
    }


    // clearing the system and initilizaing the temporery values.
    // everytime in the start and end of a file-
    public static void Initilizing_to_zero(){
        file_number = 0;
        ACC =0;
        PSIAR=0;
        SAR=0;
        SDR=0;
        TMPR=0;
        CSIAR=0;
        IR=0;
        MIR=0;
    }

    // The method prints the registers and Control Storage Instruction Address Register
    public static void print_register() {
        System.out.println("");
        System.out.println("The registers are:");
        System.out.println("the ACC is :"+ ACC);
        System.out.println("The PSIAR is: " + PSIAR);
        System.out.println("The SAR is: " + SAR);
        System.out.println("The SDR: " + SDR);
        System.out.println("The TMPR: " + TMPR);
        System.out.println("The CSIAR is: " + CSIAR);
        // NEED TO PRINT MORE?
    }

    // the method prints the memory
    public static void print_memory(){
        System.out.println("The memory is: ");
        System.out.println("");
        for (int i =0;i < Memory_Main.length; i++) {
            if (Memory_Main[i] != null) {
                System.out.print("CELL " + i + ": ");
                System.out.println(Memory_Main[i]);
            }
        }
    }

    // printing the files names
    public static void print_files(){
        System.out.println("");
        System.out.println(" The files list is: ");
        for (int k = 0; k < Holder.size(); k++) {
            PCB jobPCB = Holder.get(k);
            System.out.print(jobPCB.getFilename() );
            if (k == Holder.size() - 1) {
                System.out.println("}" + "\u001B[0m");
            } else {
                System.out.print(", ");
            }
        }
    }

    // the method, finding the files from the current directury,
    // checking they are txt files and enter them to the memory which is string so we can work with them after
    // after the function we will have the memory contain the action required from place 512 (second half)
    public static void read_files(){
        // take all the files from current library
        File curDir = new File(".");
        File[] filesList = curDir.listFiles();
        // start at 512
        int place =512;
        BufferedReader reader;
        // checking the directory isnt null
        assert filesList != null;
        // go over every file in the directory
        for (File file : filesList) {
            // checking the file is a txt file so we can read it
            if (file.isFile()&& file.getName().endsWith(".txt")) {
                String[] nameList = file.getName().split("_");
                String filename =file.getName();
                //time based on file number
                int time = Integer.parseInt(nameList[1].substring(0,nameList[1].length()-4));
                // Creates an PCB for each file add to arraylist holder
                PCB job = new PCB(time, place,filename);
                Holder.add(job);
                // reading the file and enter to memory
                try{
                    reader = new BufferedReader(new FileReader(file.getName()));
                    String line =  reader.readLine();
                    file_number++;
                    while(line!= null){

                        Memory_Main[place]= line;
                        line = reader.readLine();
                        place++;
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }else if (file.isDirectory()) {
                System.out.println(" another directory - not reading");
            }else {
                System.out.println(" the file isnt a txt file");
            }
        }
        Memory_Main[place]= "END";// adding an end to know when the running is over
        // organize the array
        // sort the link list according to the order
        Holder.sort(Comparator.comparingInt(PCB::getTime_arrived));
        print_files();
    }


    // THE FUNCTION READ THE FILES
    public static void process_run() {
        // CHECKING THERE ARE STILL PROGRAM WAITING
        while(!Holder.isEmpty())
        {
            PCB current_operation =Holder.getFirst();
            get_data(current_operation);
            // This boolean variable determines whether or not a context switch in Round Robin Fashion occurs
            boolean RoundRobin = false;
            // checking if it the time to switch PCB
            while(!fetch(PSIAR).equals("YLD")){
                int single_clock = current_operation.getTime_for_proccess();
                // every seven clocks(line of code) it will go out
                String [] Line = fetch(PSIAR).split(" ");
                change_to_function(Line[0],Integer.parseInt((Line[1])));
                // making sure the process have the same values as the system
                current_operation.save_data(ACC, PSIAR, SAR, SDR, TMPR, CSIAR, MIR, IR);
                // taking the time for the process and get it
                // add the time by 1 becuase we went over another line
                single_clock++;
                current_operation.set_time(single_clock);
                // add one to the amount of over all time (a line is one unit of time)
                overall_time++;
                // if there are too many operations (more than 7 ) enter to the end of the list
                if(single_clock % 7 ==0){
                    System.out.println(current_operation.getFilename()+ "The program had 7 operations already it is YIELD");
                    single_clock=0;// INITIALIZING THE CLOCK TO 0
                    current_operation.set_time(single_clock);
                    // move the first to the last round robin algorithm
                    // PCB first = new PCB((PCB) current_operation);
                    PCB first = new PCB(current_operation); // Creating aof the job PCB
                    Holder.addLast(first); // Adding the copy to the queue
                    Holder.removeFirst(); // Removing the original form the first place in the list
                    RoundRobin= true;
                    break;
                }
            }
            // If it is true we need to keep going to the next job
            if(RoundRobin){
                continue;
            }
            overall_time++;
            System.out.println("The file "+ current_operation.getFilename()+ " finish all of his operations");
            Holder.removeFirst();
        }
        System.out.println("Total Time: " + overall_time );
    }

    // making sure we are getting the values from the PCB to the system
    // get the information of the single proccess to make sure we are working with the right data
    public static void get_data(PCB single_proces){
        ACC = single_proces.getACC();
        PSIAR= single_proces.getPSIAR();
        CSIAR= single_proces.getCSIAR();
        SAR= single_proces.getSAR();
        SDR= single_proces.getSDR();
        TMPR= single_proces.getTMPR();
        IR= single_proces.getIR();
        MIR= single_proces.getMIR();

    }

    // FETCHING THE VALUE OF CERTAIN ADDRESS
    public static String fetch(int address){
        return Memory_Main[address];
    }

    // decoding the action back to use the function we need
    public static void change_to_function(String upcode, int data){
        switch(upcode){
            case "ADD" : ADD(data); break;
            case "SUB": SUB(data); break;
            case "LDA": LDA(data); break;
            case "STR": STR(data); break;
            case "BRH": BRH(data);break;
            case "CBR": CBR(data);break;
            case "LDI": LDI(data);break;
        }
    }

    //Where <address> holds the value to add to the accumulator.
    public  static void ADD(int address){
        TMPR = ACC;
        ACC = PSIAR + 1;
        PSIAR = ACC;
        ACC = TMPR;
        SDR = address;
        TMPR = SDR;
        SAR = TMPR;
        SDR= Integer.parseInt(Memory_Main[SAR]);
        TMPR = SDR;
        ACC = ACC + TMPR;
        CSIAR =0;
    }

    //Where <address> holds the value to subtract from the accumulator
    // THE function take the local registers and move the value to the temp adding one to PSIAR and movibg it back,
    public static void SUB(int address){
        TMPR = ACC;
        ACC = PSIAR + 1;
        PSIAR = ACC;
        ACC = TMPR;
        SDR =address;

        TMPR = SDR;
        SAR = TMPR;

        SDR= Integer.parseInt(Memory_Main[SAR]);
        TMPR = SDR;
        ACC =ACC - TMPR;
        CSIAR =0;
    }

    // the input address holds the value to load in to the accumulator.
    public static void LDA (int address){
        TMPR = ACC;
        ACC = PSIAR + 1;
        PSIAR = ACC;
        TMPR = address;
        SAR = TMPR;
        SDR= Integer.parseInt(Memory_Main[SAR]);
        ACC= SDR;
        CSIAR =0;
    }

    // Load the value into the ACC
    public static void LDI(int address) {
        SAR= PSIAR;
        ACC = PSIAR +1;
        PSIAR = ACC;
        SDR= address;
        ACC= SDR;
        CSIAR=0;
    }

    //Where <address> is the storage location for the contents of the accumulator
    public static void STR (int address){
        TMPR = ACC;
        ACC = PSIAR + 1;
        PSIAR = ACC;
        ACC = TMPR;
        TMPR = address;
        SAR = TMPR;
        SDR = ACC;
        Memory_Main[SAR]= SDR+"";
        CSIAR=0;
    }

    // Where <address> is the target of the absolute branch
    public static void BRH (int address){
        SDR = address;
        PSIAR = SDR;
        CSIAR = 0;
    }

    //Where <address> is the target of an absolute branch if the accumulator is zero.
    public static void CBR (int address){
        SDR = address;
        CSIAR = 64;
        if(ACC <= 0){
            PSIAR= SDR;
        }else{
            TMPR = ACC;
            ACC = PSIAR + 1;
            PSIAR = ACC;
            ACC = TMPR;
        }
        CSIAR = 0;
    }

}

class PCB {
    // Registers
    private int ACC;//Accumulator
    private int PSIAR;//Primary Storage Instruction Address Register;
    private int SAR;// Storage Address Register
    private int SDR;// Storage Data Register
    private int TMPR;//Temporary Register
    private int CSIAR;// Control Storage Instruction Address Register;
    private int IR;// Instruction Register;
    private int MIR;// Micro-instruction Register
    private int time_for_proccess;// the amount of line of code for the specific job
    private int file_Placment;// the way to calculate the place of file
    private String filename;

    public PCB(int time, int pointer, String Name){
        filename= Name;
        file_Placment = time;
        time_for_proccess = 0;
        PSIAR = pointer;

    }

    public PCB(PCB object){
        this.IR= object.IR;
        this.MIR= object.MIR;
        this.time_for_proccess= object.time_for_proccess;
        this.file_Placment = object.file_Placment;
        this.filename= object.filename;
        this.ACC = object.ACC;
        this.PSIAR =object.PSIAR;
        this.SAR= object.SAR;
        this.SDR= object.SDR;
        this.TMPR=object.TMPR;
        this.CSIAR = object.CSIAR;
    }

    // if time up it save the data on the object so it will be used after;
    public void save_data(int ACC, int PSIAR, int SAR, int SDR, int TMPR, int CSIAR, int MIR, int IR){
        this.ACC = ACC;
        this.PSIAR =PSIAR;
        this.SAR= SAR;
        this.SDR= SDR;
        this.TMPR= TMPR;
        this.CSIAR = CSIAR;
        this.IR= IR;
        this.MIR = MIR;
    }

    // set the time to see how long the pcb is working
    public void set_time(int time){
        time_for_proccess = time;
    }

    // getters
    public int getTime_for_proccess() {
        return time_for_proccess;
    }

    public int getTime_arrived() {
        return file_Placment;
    }

    public int getACC() {
        return ACC;
    }

    public int getCSIAR() {
        return CSIAR;
    }

    public int getSDR() {
        return SDR;
    }

    public int getPSIAR() {
        return PSIAR;
    }

    public int getSAR() {
        return SAR;
    }

    public int getTMPR() {
        return TMPR;
    }

    public int getIR() {
        return IR;
    }

    public int getMIR() {
        return MIR;
    }

    public String getFilename(){return filename;}
}
