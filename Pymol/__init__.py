from pymol import cmd
import pymol
from Tkinter import *
import os
import tkFileDialog
import subprocess


def __init__(self):
    self.menuBar.addmenuitem('Plugin', 'command', 'enlighten', label='enlighten', command=lambda : mainDialog())


# Diaglogue lables
class enlighten(Frame):
    def __init__(self, parent):
        Frame.__init__(self, parent)
        # Parent means the frame that is being used
        self.parent = parent  # This what calls the ezlig(root)
        self.initUI()

        self.selection = ""
        self.pdb = ""

    def initUI(self):
        # There are four frames in the window containing varios buttons/dropdowns etc
        self.parent.title("Enlighten Tools")
        frame4 = Frame(self.parent)
        frame4.grid(row=0, column=0, sticky="nsew")
        self.fv = IntVar()
        self.fv.set(1)
        self.file = Checkbutton(frame4, text="Choose from file", command=self.selectoption1, variable=self.fv,
                                offvalue=0, onvalue=1)
        self.file.grid(row=0, column=0)
        self.file.select()
        self.sv = IntVar()
        self.sv.set(0)
        self.sel = Checkbutton(frame4, text="Choose from selection", command=self.selectoption2, variable=self.sv,
                               offvalue=0, onvalue=1)
        self.sel.grid(row=0, column=1)
        self.sel.deselect()

        # Now move onto frame one
        frame1 = Frame(self.parent)
        frame1.grid(row=1, column=0)
        lbl1 = Label(frame1, text="PDB file", width=12)
        lbl1.grid(row=0, column=0)
        self.entry1 = Entry(frame1)
        self.entry1.grid(row=0, column=1, columnspan=4, sticky=W + E)
        self.browserButton = Button(frame1, text="Browser", command=self.onOpenF)
        self.browserButton.grid(row=0, column=5, sticky="e")
        lbl2 = Label(frame1, text="enlighten Folder", width=12)
        lbl2.grid(row=1, column=0)
        self.enlightenpath = Entry(frame1)
        self.enlightenpath.insert(END, '/Users/simonbennie/enlighten') #fixme
        self.enlightenpath.grid(row=1, column=1, columnspan=4, sticky=W + E)
        enlightenButton = Button(frame1, text="Browser", command=self.onOpen)
        enlightenButton.grid(row=1, column=5, sticky="e")
        lbl3 = Label(frame1, text="AMBER Folder", width=12)
        lbl3.grid(row=2, column=0)
        self.amberpath = Entry(frame1)
        self.amberpath.grid(row=2, column=1, columnspan=4, sticky=W + E)
        amberButton = Button(frame1, text="Browser", command=self.onOpenA)
        amberButton.grid(row=2, column=5, sticky="e")
        # This will auto find the amber installation from the environment variables
        self.amberpath.insert(0, os.environ.get('AMBERHOME', 'Please specify AMBER home directory'))
        # self.amberpath.insert(END, '/Users/simonbennie/bin/amber14') # Fixme

        lbl4 = Label(frame1, text="Output Folder", width=12)
        lbl4.grid(row=3, column=0)
        self.workingpath = Entry(frame1)
        self.workingpath.insert(END, '/Users/simonbennie') # Fixme
        self.workingpath.grid(row=3, column=1, columnspan=4, sticky=W + E)
        outputButton = Button(frame1, text="Browser", command=self.onOpenO)
        outputButton.grid(row=3, column=5, sticky="e")
        lbl5 = Label(frame1, text="Ligand Name", width=12)
        lbl5.grid(row=4, column=0)
        self.ligandname = Entry(frame1)
        self.ligandname.insert(END, '0RN') # Fixme
        self.ligandname.grid(row=4, column=1)
        lbl6 = Label(frame1, text="Ligand Charge", width=12)
        lbl6.grid(row=4, column=2)
        self.entry6 = Entry(frame1)
        self.entry6.insert(END, '-1')
        self.entry6.grid(row=4, column=3)

        # This is where frame two starts
        frame2 = Frame(self.parent)
        frame2.grid(row=2, column=0, sticky="nsew")
        # This next section constructs a boz plus the scroll bar and reaction to user input.
        self.vsb = Scrollbar(frame2, orient="vertical", command=self.OnVsb)
        self.vsb.grid(row=0, column=2, sticky="ns")
        lbl7 = Label(frame2, text="List of Selection", width=12)
        lbl7.grid(row=0, column=0)
        self.lb1 = Listbox(frame2, yscrollcommand=self.vsb.set)
        self.lb1.grid(row=0, column=1)
        self.lb1.bind("<MouseWheel>", self.OnMouseWheel)
        self.lb1.bind("<<ListboxSelect>>", self.OnSelect)
        for x in cmd.get_names("all"):
            self.lb1.insert(END, x)
        self.lb1.config(state=DISABLED)

        # Time steps for use in dynamm
        lbl7 = Label(frame1, text="Time steps (ps)", width=12)
        lbl7.grid(row=5, column=2)
        self.entry7 = Entry(frame1)
        self.entry7.insert(END, '100')
        self.entry7.grid(row=5, column=3)
        self.nstlim = int(self.entry7.get())/500  # Convert to time steps

        # self.vsb.config(state=DISABLED)
        frame3 = Frame(self.parent)
        frame3.grid(row=3, column=0, sticky="nsew")
        # Three lower buttons in the plugin
        self.prepButton = Button(frame3, text="RUN PREP", command=self.runprep)
        self.prepButton.grid(row=0, column=0, sticky="e")
        self.structButton = Button(frame3, text="RUN STRUCT", command=self.runstruct)
        self.structButton.grid(row=0, column=1, sticky="e")
        self.structButton.config(state=DISABLED)
        self.dynamButton = Button(frame3, text="RUN DYNAM", command=self.rundynam)
        self.dynamButton.grid(row=0, column=2, sticky="e")
        self.dynamButton.config(state=DISABLED)

    # This next section defines a series of dialogues that are opened according the the actions from above
    def onOpenF(self):
        pdb = tkFileDialog.askopenfilename()
        self.entry1.delete(0, 'end')
        self.entry1.insert(0, pdb)
        path = os.path.split(pdb)
        self.workingpath.delete(0, 'end')
        self.workingpath.insert(0, path[0])

    def onOpenA(self):
        amber = tkFileDialog.askdirectory()
        self.amberpath.delete(0, 'end')
        self.amberpath.insert(0, amber)

    def onOpenO(self):
        out = tkFileDialog.askdirectory()
        self.workingpath.delete(0, 'end')
        self.workingpath.insert(0, out)

    def onOpen(self):
        fold = tkFileDialog.askdirectory()
        self.enlightenpath.delete(0, 'end')
        self.enlightenpath.insert(0, fold)

    def OnVsb(self, *args):
        self.lb1.yview(*args) # Moves the scroll bar

    def OnMouseWheel(self, event):
        self.lb1.yview("scroll", event.delta, "units")

    # Saves the selection for use
    def OnSelect(self, val):
        sender = val.widget
        idx = sender.curselection()
        self.selection = self.lb1.get(idx)

    # Diables the option that are not valid for selection with the first two tick boxes
    def selectoption1(self):
        self.sel.toggle()
        if (self.fv.get() == 0):
            self.fv.set(1)
            self.sv.set(0)
            self.entry1.config(state="normal")
            self.browserButton.config(state="normal")
            self.lb1.config(state=DISABLED)
            self.lb1.delete(0, 'end')

            for x in cmd.get_names("all"):
                self.lb1.insert(END, x)
        else:
            self.fv.set(0)
            self.sv.set(1)
            self.entry1.config(state=DISABLED)
            self.browserButton.config(state=DISABLED)
            self.lb1.config(state="normal")
            # self.vsb.config(state="normal")
            self.lb1.delete(0, 'end')

            for x in cmd.get_names("all"):
                self.lb1.insert(END, x)

                # print self.fv.get()
                # print self.sv.get()

    def selectoption2(self):
        self.file.toggle()
        if (self.sv.get() == 0):
            self.fv.set(0)
            self.sv.set(1)
            self.entry1.config(state=DISABLED)
            self.browserButton.config(state=DISABLED)
            self.lb1.config(state="normal")
            self.lb1.delete(0, 'end')

            for x in cmd.get_names("all"):
                self.lb1.insert(END, x)

        else:
            self.sv.set(0)
            self.fv.set(1)
            self.entry1.config(state="normal")
            self.browserButton.config(state="normal")
            self.lb1.config(state=DISABLED)
            # self.vsb.config(state="normal")
            self.lb1.delete(0, 'end')

            for x in cmd.get_names("all"):
                self.lb1.insert(END, x)

                # print self.fv.get()
                # print self.sv.get()

    def runprep(self):
        if self.fv.get() == 1:
            os.chdir(self.workingpath.get())
            os.environ["AMBERHOME"] = self.amberpath.get()
            # Saves the command for use
            command = self.enlightenpath.get() + "/prep.sh " + os.path.basename(
                self.entry1.get()) + " " + self.ligandname.get() + " " + self.entry6.get()
            #Executes the comman passed above
            p = subprocess.Popen([command], shell=True, stderr=subprocess.PIPE)
            # This initates a wait for the output to complete before the next stage is run
            while True:
                out = p.stderr.read(1)
                if out == '' and p.poll() != None:
                    break
                if out != '':
                    sys.stdout.write(out)
                    sys.stdout.flush()
            print("Job Finished")
            path = os.path.split(self.entry1.get())
            temp = path[1].split('.')
            # First loads the topology file
            pymol.cmd.load("./" + temp[0] + "/" + temp[0] + ".sp20.top", temp[0] + ".sp20")
            # Loads the pdb
            pymol.cmd.load("./" + temp[0] + "/" + temp[0] + ".sp20.pdb", temp[0] + ".sp20")
            self.pdb = os.path.basename(self.entry1.get())
        # The difference between this and obe is the entry selection
        if self.sv.get() == 1:
            os.chdir(self.workingpath.get())
            print(os.chdir(self.workingpath.get()))
            cmd.save(self.workingpath.get() + "/" + self.selection + ".pdb", self.selection)
            os.environ["AMBERHOME"] = self.amberpath.get()
            os.environ["PATH"] = os.environ["PATH"] + ":" + os.environ["AMBERHOME"] + "/bin"
            command = self.enlightenpath.get() + "/prep.sh " + self.selection + ".pdb" + " " + self.ligandname.get() +\
                      " " + self.entry6.get()
            p = subprocess.Popen([command], shell=True, stderr=subprocess.PIPE)
            while True:
                out = p.stderr.read(1)
                # if out == '' and p.poll() != None:
                #     break
                # if out != '':
                sys.stdout.write(out)
                sys.stdout.flush()
            print "Job Finished"
            temp = self.selection
            print(temp)
            pymol.cmd.load("./" + temp + "/" + temp + ".sp20.top", temp + ".sp20")
            pymol.cmd.load("./" + temp +"/" + temp +  ".sp20.pdb", temp + ".sp20") # fixme
            self.pdb = self.selection + ".pdb"
        self.structButton.config(state="normal")
        os.environ["enlighten"] = self.enlightenpath.get()

    def runstruct(self):
        command = self.enlightenpath.get() + "/struct/struct.sh " + self.pdb + " " + self.ligandname.get() +\
                  " " + self.entry6.get()
        p = subprocess.Popen([command], shell=True, stderr=subprocess.PIPE)
        while True:
            out = p.stderr.read(1)
            #if out == '' and p.poll() != None:
            #    break
            #if out != '':
            sys.stdout.write(out)
            sys.stdout.flush()
        temp = self.pdb[:-4]
        pymol.cmd.load("./" + temp +"/"+ temp + ".sp20.rst", temp + ".sp20")
        self.dynamButton.config(state="normal")
        print "Job Finished"

    # Run a dynamics calculation on the given structure
    # - heat.i: Brief heating(only 5 ps MD), meant to run with output from struct.sh (min_sa_ *.rst).
    # - md.i: 100 ps NVT MD, to follow heat.i.Writes and keeps restart files every 25 ps(12500 steps).
    # - min.i: Brief minimization(optionally performed after md.i).
    def rundynam(self):
        # heating command
        top=temp+".sp20.top"
        rst=temp+".sp20.rst"

        dynam(self.amberpath,top,rst,self.nstlim,self.ligandname)
        while True:
            out = p.stderr.read(1)
           # if out == '' and p.poll() != None:
           #     break
           # if out != '':
            sys.stdout.write(out)
            sys.stdout.flush()
        temp = self.pdb[:-4]
        pymol.cmd.load("./" + temp + "/struct/min_sa_" + temp + ".sp20.trj", temp + ".trj")
        print "Job Finished"

def mainDialog():
    # Tk is a tinker python gui library, This is the default toolkit used in pymol
    root = Tk()
    root.resizable(0, 0)  # currently not resizable due to lack of reflow
    enlighten(root)  # This is where the nezlig class is called, passes the parent frame
    root.mainloop()
